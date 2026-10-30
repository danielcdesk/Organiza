import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/data/local_repository.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/financial_rules.dart';
import 'package:organiza/domain/models.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('restaura JSON histórico criando o schema de origem antes de migrar',
      () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);

    database.restoreSnapshot(_versionOneSnapshot());

    expect(database.schemaVersion, AppDatabase.currentSchemaVersion);
    expect(database.loadAccounts().single.name, 'Conta histórica');
    expect(database.loadTransactions().single.description, 'Mercado histórico');
    expect(database.loadTransactions().single.category, 'Outros');
    expect(
      FinancialRules.currentBalance(
        database.loadAccounts(),
        database.loadTransactions(),
      ),
      88000,
    );
    expect(database.loadTasks().single.title, 'Tarefa histórica');
  });

  test('recusa tabela inesperada no snapshot sem alterar o banco', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    final snapshot = Map<String, dynamic>.from(database.exportSnapshot());
    final tables = Map<String, Object?>.from(snapshot['tables'] as Map);
    tables['unexpected'] = <Object?>[];
    snapshot['tables'] = tables;

    expect(() => database.restoreSnapshot(snapshot), throwsFormatException);
    expect(database.loadAccounts(), isEmpty);
  });

  test('cópia consistente inclui WAL e preserva saldos e preferências',
      () async {
    final file = _temporaryDatabase();
    final database = AppDatabase.openFile(file);
    addTearDown(database.close);
    _insertCurrentData(database);
    database.savePreference('theme', 'light');
    expect(File('${file.path}-wal').existsSync(), isTrue);
    final destination = File(path.join(file.parent.path, 'snapshot.db'));

    await database.createConsistentCopy(destination);

    final copied = AppDatabase.openFile(destination, migrate: false);
    addTearDown(copied.close);
    copied.validateIntegrity();
    expect(copied.tableCounts, database.tableCounts);
    expect(copied.loadPreference('theme'), 'light');
    expect(_balance(copied), 88000);
    expect(copied.filePath, destination.absolute.path);
    expect(AppDatabase.currentSchemaVersion, 18);
    await expectLater(
      database.createConsistentCopy(file),
      throwsArgumentError,
    );
    expect(_balance(database), 88000);
  });

  test('migra arquivo v1 já preenchido e reabrir é idempotente', () async {
    final file = _temporaryDatabase();
    final source = AppDatabase.openInMemoryAtVersionForTest(1);
    source.restoreSnapshot(_versionOneSnapshot());
    await source.createConsistentCopy(file);
    source.close();

    var database = AppDatabase.openFile(file);
    expect(database.schemaVersion, AppDatabase.currentSchemaVersion);
    expect(_balance(database), 88000);
    expect(database.loadTasks().single.title, 'Tarefa histórica');
    database.validateIntegrity();
    final snapshot = database.exportSnapshot();
    database.close();

    final beforeMigration = AppDatabase.openFile(
      File('${file.path}.pre-v${AppDatabase.currentSchemaVersion}.bak'),
      migrate: false,
    );
    expect(beforeMigration.schemaVersion, 1);
    expect(beforeMigration.tableCounts['transactions'], 1);
    beforeMigration.validateIntegrity();
    beforeMigration.close();

    database = AppDatabase.openFile(file);
    addTearDown(database.close);
    expect(database.exportSnapshot(), snapshot);
    expect(_balance(database), 88000);
  });

  test('migra arquivo v15 preenchido sem alterar parcelas ou saldo', () async {
    final file = _temporaryDatabase();
    final source = AppDatabase.openInMemoryAtVersionForTest(15);
    _insertCurrentData(source);
    source.insertCreditCard(CreditCard(
      id: 'card',
      name: 'Cartão',
      brand: CardBrand.visa,
      lastFour: '4242',
      limitInCents: 100000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0,
      createdAt: DateTime(2026, 9, 1),
    ));
    source.insertCardPurchase(CardPurchase(
      id: 'purchase',
      cardId: 'card',
      description: 'Compra parcelada',
      amountInCents: 10001,
      purchasedOn: DateTime(2026, 9, 1),
      installments: 3,
      createdAt: DateTime(2026, 9, 1),
    ));
    await source.createConsistentCopy(file);
    source.close();

    final database = AppDatabase.openFile(file);
    addTearDown(database.close);
    database.validateIntegrity();
    expect(database.schemaVersion, AppDatabase.currentSchemaVersion);
    expect(_balance(database), 88000);
    expect(database.loadCardPurchases().single.amountInCents, 10001);
    expect(database.loadCardPurchases().single.paidInstallments, isEmpty);
    expect(database.tableCounts['card_installment_payments'], 0);
  });

  test('falha durante migração reverte DDL e versão e permite nova tentativa',
      () async {
    final file = _temporaryDatabase();
    final source = AppDatabase.openInMemoryAtVersionForTest(1);
    source.restoreSnapshot(_versionOneSnapshot());
    await source.createConsistentCopy(file);
    source.close();
    final raw = sqlite3.open(file.path);
    raw.execute('CREATE INDEX idx_card_purchases_card_date ON accounts(name)');
    raw.close();

    expect(() => AppDatabase.openFile(file), throwsA(isA<SqliteException>()));

    final unchanged = sqlite3.open(file.path);
    expect(unchanged.select('PRAGMA user_version').single.values.single, 1);
    expect(
      unchanged
          .select("SELECT name FROM sqlite_master WHERE name='credit_cards'"),
      isEmpty,
    );
    expect(
        unchanged
            .select('SELECT COUNT(*) FROM transactions')
            .single
            .values
            .single,
        1);
    unchanged.execute('DROP INDEX idx_card_purchases_card_date');
    unchanged.close();
    final database = AppDatabase.openFile(file);
    addTearDown(database.close);
    database.validateIntegrity();
    expect(_balance(database), 88000);
    expect(
        File('${file.path}.pre-v${AppDatabase.currentSchemaVersion}.bak')
            .existsSync(),
        isTrue);
  });

  test('retenção mantém três cópias somente após migração íntegra', () async {
    final file = _temporaryDatabase();
    final source = AppDatabase.openInMemoryAtVersionForTest(1);
    await source.createConsistentCopy(file);
    source.close();
    for (var version = 1; version <= 4; version++) {
      final copy = file.copySync('${file.path}.pre-v$version.bak');
      copy.setLastModifiedSync(DateTime(2020, 1, version));
    }
    final database = AppDatabase.openFile(file);
    addTearDown(database.close);

    expect(
      file.parent
          .listSync()
          .whereType<File>()
          .where((entry) => entry.path.endsWith('.bak')),
      hasLength(3),
    );
    expect(
        File('${file.path}.pre-v${AppDatabase.currentSchemaVersion}.bak')
            .existsSync(),
        isTrue);
    expect(File('${file.path}.pre-v1.bak').existsSync(), isFalse);
  });

  test('reescrita de imagens aplica cada referência original uma só vez', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.close);
    database.savePreference('profile_photo_path', 'old-a');
    database.insertShoppingItem(ShoppingItem(
      id: 'item',
      name: 'Item',
      quantity: 1,
      imagePath: 'old-b',
      createdAt: DateTime(2026, 9, 1),
    ));

    database.rewriteImagePaths({'old-a': 'old-b', 'old-b': 'images/item.png'});

    expect(database.loadPreference('profile_photo_path'), 'old-b');
    expect(database.loadShoppingItems().single.imagePath, 'images/item.png');
  });

  test('reescrita de imagens reverte perfil se atualização de item falhar', () {
    final file = _temporaryDatabase();
    final database = AppDatabase.openFile(file);
    addTearDown(database.close);
    database.savePreference('profile_photo_path', 'old');
    database.insertShoppingItem(ShoppingItem(
      id: 'item',
      name: 'Item',
      quantity: 1,
      imagePath: 'old',
      createdAt: DateTime(2026, 9, 1),
    ));
    final raw = sqlite3.open(file.path);
    addTearDown(raw.close);
    raw.execute('''CREATE TRIGGER stop_image_update BEFORE UPDATE OF image_path
      ON shopping_items BEGIN SELECT RAISE(ABORT, 'falha simulada'); END''');

    expect(
      () => database.rewriteImagePaths({'old': 'images/item.png'}),
      throwsA(isA<SqliteException>()),
    );
    expect(database.loadPreference('profile_photo_path'), 'old');
    expect(database.loadShoppingItems().single.imagePath, 'old');
    raw.execute('DROP TRIGGER stop_image_update');
  });

  test('integridade rejeita FK inválida e coluna não reconhecida', () {
    final file = _temporaryDatabase();
    final database = AppDatabase.openFile(file);
    addTearDown(database.close);
    final raw = sqlite3.open(file.path);
    addTearDown(raw.close);
    raw.execute('''INSERT INTO transactions
      (id, account_id, type, amount_cents, description, occurred_on, created_at)
      VALUES ('bad', 'missing', 'expense', 1, '', '2026-09-01', '2026-09-01')''');
    expect(database.validateIntegrity, throwsFormatException);
    raw.execute('DELETE FROM transactions');
    database.validateIntegrity();
    raw.execute('ALTER TABLE accounts ADD COLUMN unexpected TEXT');
    expect(database.validateIntegrity, throwsFormatException);
  });

  test('repositório fecha e reabre conexão após substituição externa',
      () async {
    final live = _temporaryDatabase();
    final repository = LocalRepository.openAtFile(live);
    addTearDown(repository.close);
    repository.savePreference('theme', 'dark');
    final staged = File(path.join(live.parent.path, 'staged.db'));
    final replacement = AppDatabase.openFile(staged);
    replacement.savePreference('theme', 'light');
    replacement.close();

    repository.closeForReplacement();
    staged.copySync(live.path);
    repository.reopenAfterReplacement();

    expect(repository.filePath, live.absolute.path);
    expect(repository.loadPreference('theme'), 'light');
    repository.validateIntegrity();
    expect(repository.reopenAfterReplacement, throwsStateError);
    final inMemory = LocalRepository.inMemory();
    addTearDown(inMemory.close);
    expect(inMemory.closeForReplacement, throwsStateError);
  });
}

File _temporaryDatabase() {
  final directory = Directory.systemTemp.createTempSync('organiza-db-core-');
  addTearDown(() => directory.deleteSync(recursive: true));
  return File(path.join(directory.path, 'organiza.db'));
}

int _balance(AppDatabase database) => FinancialRules.currentBalance(
      database.loadAccounts(),
      database.loadTransactions(),
    );

void _insertCurrentData(AppDatabase database) {
  database.insertAccount(Account(
    id: 'account',
    name: 'Principal',
    openingBalanceInCents: 100000,
    createdAt: DateTime(2026, 9, 1),
  ));
  database.insertTransaction(TransactionRecord(
    id: 'transaction',
    accountId: 'account',
    type: TransactionType.expense,
    amountInCents: 12000,
    description: 'Mercado',
    occurredOn: DateTime(2026, 9, 2),
    createdAt: DateTime(2026, 9, 2),
  ));
}

Map<String, dynamic> _versionOneSnapshot() => {
      'schemaVersion': 1,
      'tables': {
        'accounts': [
          {
            'id': 'old-account',
            'name': 'Conta histórica',
            'opening_balance_cents': 100000,
            'created_at': '2026-09-01T00:00:00.000',
          },
        ],
        'transactions': [
          {
            'id': 'old-transaction',
            'account_id': 'old-account',
            'destination_account_id': null,
            'type': 'expense',
            'amount_cents': 12000,
            'description': 'Mercado histórico',
            'occurred_on': '2026-09-02T00:00:00.000',
            'created_at': '2026-09-02T00:00:00.000',
          },
        ],
        'tasks': [
          {
            'id': 'old-task',
            'title': 'Tarefa histórica',
            'due_on': null,
            'is_done': 0,
            'created_at': '2026-09-01T00:00:00.000',
          },
        ],
      },
    };
