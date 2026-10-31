import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/financial_rules.dart';
import 'package:organiza/domain/models.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('schema 1 chega ao atual com categoria e saldo preservados', () async {
    final folder =
        await Directory.systemTemp.createTemp('organiza-category-v1-');
    addTearDown(() => folder.delete(recursive: true));
    final file = File(path.join(folder.path, 'organiza.db'));
    final old = AppDatabase.openInMemoryAtVersionForTest(1);
    old.restoreSnapshot({
      'schemaVersion': 1,
      'tables': {
        'accounts': [
          {
            'id': 'account',
            'name': 'Antiga',
            'opening_balance_cents': 50000,
            'created_at': '2024-01-01T00:00:00.000',
          }
        ],
        'transactions': [
          {
            'id': 'expense',
            'account_id': 'account',
            'destination_account_id': null,
            'type': 'expense',
            'amount_cents': 2500,
            'description': 'Histórico',
            'occurred_on': '2024-01-02T00:00:00.000',
            'created_at': '2024-01-02T00:00:00.000',
          }
        ],
        'tasks': <Map<String, Object?>>[],
      },
    });
    await old.createConsistentCopy(file);
    old.close();

    final database = AppDatabase.openFile(file);
    expect(database.schemaVersion, AppDatabase.currentSchemaVersion);
    expect(
        FinancialRules.currentBalance(
            database.loadAccounts(), database.loadTransactions()),
        47500);
    database.validateIntegrity();
    database.close();
    final raw = sqlite3.open(file.path);
    expect(
        raw.select('SELECT category_id FROM transactions').single.values.single,
        isNotNull);
    expect(raw.select('PRAGMA foreign_key_check'), isEmpty);
    raw.close();
  });

  test('schema 16 migra categorias históricas sem alterar saldo', () async {
    final folder =
        await Directory.systemTemp.createTemp('organiza-category-v17-');
    AppDatabase? active;
    Database? rawDatabase;
    addTearDown(() async {
      rawDatabase?.close();
      active?.close();
      await folder.delete(recursive: true);
    });
    final file = File(path.join(folder.path, 'organiza.db'));
    final source = AppDatabase.openInMemoryAtVersionForTest(16);
    source.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 100000,
      createdAt: DateTime(2026, 1, 1),
    ));
    source.insertAccount(Account(
      id: 'other-account',
      name: 'Reserva',
      openingBalanceInCents: 0,
      createdAt: DateTime(2026, 1, 1),
    ));
    for (final (id, type, cents, category, subcategory) in [
      ('expense', TransactionType.expense, 12000, 'Mercado Único', 'Padaria'),
      ('income', TransactionType.income, 2000, 'Outros', 'Geral'),
      ('shared-expense', TransactionType.expense, 1, 'Outros', 'Geral'),
    ]) {
      source.insertTransaction(TransactionRecord(
        id: id,
        accountId: 'account',
        type: type,
        amountInCents: cents,
        description: id,
        occurredOn: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2),
        category: category,
        subcategory: subcategory,
      ));
    }
    source.insertTransaction(TransactionRecord(
      id: 'transfer',
      accountId: 'account',
      destinationAccountId: 'other-account',
      type: TransactionType.transfer,
      amountInCents: 300,
      description: 'Entre contas',
      occurredOn: DateTime(2026, 1, 2),
      createdAt: DateTime(2026, 1, 2),
    ));
    source.insertBudget(Budget(
      id: 'budget',
      category: 'Mercado Único',
      limitInCents: 50000,
      year: 2026,
      month: 1,
      createdAt: DateTime(2026, 1, 1),
    ));
    source.insertSubscription(Subscription(
      id: 'subscription',
      name: 'Clube',
      amountInCents: 1000,
      billingDay: 10,
      category: 'Mercado Único',
      createdAt: DateTime(2026, 1, 1),
    ));
    source.insertFinancialGoal(FinancialGoal(
      id: 'goal',
      name: 'Curso',
      targetInCents: 20000,
      savedInCents: 5000,
      category: 'Estudos Avançados',
      createdAt: DateTime(2026, 1, 1),
    ));
    final before = FinancialRules.currentBalance(
        source.loadAccounts(), source.loadTransactions());
    await source.createConsistentCopy(file);
    source.close();

    var migrated = AppDatabase.openFile(file);
    active = migrated;
    expect(migrated.schemaVersion, AppDatabase.currentSchemaVersion);
    expect(
        FinancialRules.currentBalance(
            migrated.loadAccounts(), migrated.loadTransactions()),
        before);
    migrated.validateIntegrity();
    final raw = sqlite3.open(file.path);
    rawDatabase = raw;
    final rows = raw.select(
        'SELECT id, category_id, subcategory_id FROM transactions ORDER BY id');
    final expense = rows.singleWhere((row) => row['id'] == 'expense');
    final income = rows.singleWhere((row) => row['id'] == 'income');
    final sharedExpense =
        rows.singleWhere((row) => row['id'] == 'shared-expense');
    expect(expense['category_id'], isNotNull);
    expect(expense['subcategory_id'], isNotNull);
    expect(income['category_id'], isNot(sharedExpense['category_id']));
    final transfer = rows.singleWhere((row) => row['id'] == 'transfer');
    expect(transfer['category_id'], isNull);
    expect(transfer['subcategory_id'], isNull);
    expect(raw.select('SELECT category_id FROM budgets').single.values.single,
        expense['category_id']);
    expect(
        raw
            .select('SELECT category_id FROM subscriptions')
            .single
            .values
            .single,
        expense['category_id']);
    expect(
        raw
            .select('SELECT goal_category_name FROM financial_goals')
            .single
            .values
            .single,
        'Estudos Avançados');
    expect(raw.select('PRAGMA foreign_key_check'), isEmpty);
    raw.close();
    rawDatabase = null;
    final snapshot = migrated.exportSnapshot();
    migrated.close();
    active = null;

    migrated = AppDatabase.openFile(file);
    active = migrated;
    expect(migrated.exportSnapshot(), snapshot);
    expect(migrated.schemaVersion, AppDatabase.currentSchemaVersion);
    migrated.validateIntegrity();
    migrated.close();
    active = null;
    expect(await File('${file.path}.pre-v19.bak').exists(), isTrue);
  });
}
