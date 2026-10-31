import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('excluir lançamento conserva a linha como tombstone', () {
    final database = AppDatabase.openInMemoryAtVersionForTest(19);
    addTearDown(database.close);
    final createdAt = DateTime.utc(2026, 1, 1);
    database.insertAccount(Account(
      id: 'account-delete',
      name: 'Principal',
      openingBalanceInCents: 10000,
      createdAt: createdAt,
    ));
    database.insertTransaction(TransactionRecord(
      id: 'transaction-delete',
      accountId: 'account-delete',
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Teste',
      occurredOn: createdAt,
      createdAt: createdAt,
    ));

    database.softDelete(
      SoftDeleteEntity.transaction,
      'transaction-delete',
      DateTime.utc(2026, 2, 3),
    );

    final transactions = ((database.exportSnapshot()['tables']
            as Map<Object?, Object?>)['transactions'] as List)
        .cast<Map<Object?, Object?>>();
    expect(transactions, hasLength(1));
    expect(transactions.single['deleted_at'], isNotNull);
    expect(database.loadTransactions(), isEmpty);
  });

  test('exclusão e restauração são idempotentes e atualizam auditoria', () {
    final database = AppDatabase.openInMemoryAtVersionForTest(19);
    addTearDown(database.close);
    final createdAt = DateTime.utc(2026, 1, 1);
    database.insertAccount(Account(
      id: 'account-restore',
      name: 'Principal',
      openingBalanceInCents: 0,
      createdAt: createdAt,
    ));

    expect(
      database.softDelete(
        SoftDeleteEntity.account,
        'account-restore',
        DateTime.utc(2026, 2, 3),
      ),
      isTrue,
    );
    expect(
      database.softDelete(
        SoftDeleteEntity.account,
        'account-restore',
        DateTime.utc(2026, 2, 4),
      ),
      isFalse,
    );
    expect(database.loadAccounts(), isEmpty);
    expect(
        database.restore(SoftDeleteEntity.account, 'account-restore'), isTrue);
    expect(
        database.restore(SoftDeleteEntity.account, 'account-restore'), isFalse);
    expect(database.loadAccounts(), hasLength(1));
    final row = ((database.exportSnapshot()['tables']
            as Map<Object?, Object?>)['accounts'] as List)
        .cast<Map<Object?, Object?>>()
        .single;
    expect(row['deleted_at'], isNull);
    expect(row['updated_at'], isNotEmpty);
    expect(
      database.softDelete(
          SoftDeleteEntity.account, 'missing', DateTime.utc(2026, 2, 3)),
      isFalse,
    );
    expect(database.restore(SoftDeleteEntity.account, 'missing'), isFalse);
  });

  test('leituras comuns ocultam tombstones das dez entidades', () async {
    final folder =
        await Directory.systemTemp.createTemp('organiza-read-filter-');
    addTearDown(() => folder.delete(recursive: true));
    final database = AppDatabase.openFile(
      File(path.join(folder.path, 'organiza.db')),
    );
    addTearDown(database.close);
    final createdAt = DateTime.utc(2026, 1, 1);

    database.insertAccount(Account(
      id: 'account-live',
      name: 'Ativa',
      openingBalanceInCents: 100000,
      createdAt: createdAt,
    ));
    database.insertAccount(Account(
      id: 'account-deleted',
      name: 'Excluída',
      openingBalanceInCents: 100000,
      createdAt: createdAt,
    ));
    for (final (id, accountId) in const [
      ('transaction-live', 'account-live'),
      ('transaction-deleted', 'account-deleted'),
    ]) {
      database.insertTransaction(TransactionRecord(
        id: id,
        accountId: accountId,
        type: TransactionType.expense,
        amountInCents: 1000,
        description: id,
        occurredOn: createdAt,
        createdAt: createdAt,
      ));
    }
    for (final (id, name) in const [
      ('card-live', 'Ativo'),
      ('card-deleted', 'Excluído'),
    ]) {
      database.insertCreditCard(CreditCard(
        id: id,
        name: name,
        brand: CardBrand.visa,
        lastFour: '1234',
        limitInCents: 500000,
        closingDay: 10,
        dueDay: 17,
        colorValue: 0xff245943,
        createdAt: createdAt,
      ));
    }
    for (final (id, cardId) in const [
      ('purchase-live', 'card-live'),
      ('purchase-deleted', 'card-deleted'),
    ]) {
      database.insertCardPurchase(CardPurchase(
        id: id,
        cardId: cardId,
        description: id,
        amountInCents: 5000,
        purchasedOn: createdAt,
        installments: 1,
        createdAt: createdAt,
      ));
    }
    for (final id in const ['investment-live', 'investment-deleted']) {
      database.insertInvestment(InvestmentPosition(
        id: id,
        name: id,
        type: InvestmentType.fixedIncome,
        investedAmountInCents: 10000,
        currentValueInCents: 10500,
        createdAt: createdAt,
      ));
    }
    for (final (id, month) in const [
      ('budget-live', 1),
      ('budget-deleted', 2),
    ]) {
      database.insertBudget(Budget(
        id: id,
        category: 'Alimentação',
        limitInCents: 20000,
        year: 2026,
        month: month,
        createdAt: createdAt,
      ));
    }
    for (final id in const ['subscription-live', 'subscription-deleted']) {
      database.insertSubscription(Subscription(
        id: id,
        name: id,
        amountInCents: 1000,
        billingDay: 10,
        category: 'Outros',
        createdAt: createdAt,
      ));
    }
    for (final id in const ['goal-live', 'goal-deleted']) {
      database.insertFinancialGoal(FinancialGoal(
        id: id,
        name: id,
        targetInCents: 10000,
        savedInCents: 1000,
        createdAt: createdAt,
      ));
    }
    for (final id in const ['shopping-live', 'shopping-deleted']) {
      database.insertShoppingItem(ShoppingItem(
        id: id,
        name: id,
        quantity: 1,
        createdAt: createdAt,
      ));
    }
    for (final id in const ['task-live', 'task-deleted']) {
      database.insertTask(TaskItem(
        id: id,
        title: id,
        createdAt: createdAt,
      ));
    }

    final raw = sqlite3.open(database.filePath!);
    for (final (table, id) in const [
      ('accounts', 'account-deleted'),
      ('transactions', 'transaction-deleted'),
      ('credit_cards', 'card-deleted'),
      ('card_purchases', 'purchase-deleted'),
      ('investments', 'investment-deleted'),
      ('budgets', 'budget-deleted'),
      ('subscriptions', 'subscription-deleted'),
      ('financial_goals', 'goal-deleted'),
      ('shopping_items', 'shopping-deleted'),
      ('tasks', 'task-deleted'),
    ]) {
      raw.execute('UPDATE "$table" SET deleted_at = ? WHERE id = ?',
          ['2026-02-01T00:00:00.000Z', id]);
    }
    raw.close();

    expect(
        database.loadAccounts().map((row) => row.id).toSet(), {'account-live'});
    expect(database.loadTransactions().map((row) => row.id).toSet(),
        {'transaction-live'});
    expect(
        database.loadCreditCards().map((row) => row.id).toSet(), {'card-live'});
    expect(database.loadCardPurchases().map((row) => row.id).toSet(),
        {'purchase-live'});
    expect(database.loadInvestments().map((row) => row.id).toSet(),
        {'investment-live'});
    expect(
        database.loadBudgets().map((row) => row.id).toSet(), {'budget-live'});
    expect(database.loadSubscriptions().map((row) => row.id).toSet(),
        {'subscription-live'});
    expect(database.loadFinancialGoals().map((row) => row.id).toSet(),
        {'goal-live'});
    expect(database.loadShoppingItems().map((row) => row.id).toSet(),
        {'shopping-live'});
    expect(database.loadTasks().map((row) => row.id).toSet(), {'task-live'});
  });

  test('snapshot mantém tombstones e restaura-os junto dos registros ativos',
      () async {
    final folder =
        await Directory.systemTemp.createTemp('organiza-backup-tombstones-');
    addTearDown(() => folder.delete(recursive: true));
    final database = AppDatabase.openFile(
      File(path.join(folder.path, 'organiza.db')),
    );
    addTearDown(database.close);
    database.insertAccount(Account(
      id: 'account-deleted',
      name: 'Conta preservada',
      openingBalanceInCents: 1000,
      createdAt: DateTime.utc(2026, 1, 1),
    ));
    final raw = sqlite3.open(database.filePath!);
    raw.execute(
      "UPDATE accounts SET deleted_at = '2026-02-01T00:00:00.000Z' WHERE id = 'account-deleted'",
    );
    raw.close();

    final snapshot = database.exportSnapshot();
    final accountRows =
        ((snapshot['tables'] as Map<Object?, Object?>)['accounts'] as List)
            .cast<Map<Object?, Object?>>();
    expect(accountRows, hasLength(1));
    expect(accountRows.single['deleted_at'], '2026-02-01T00:00:00.000Z');
    database.restoreSnapshot(Map<String, dynamic>.from(snapshot));
    final restoredRows = ((database.exportSnapshot()['tables']
            as Map<Object?, Object?>)['accounts'] as List)
        .cast<Map<Object?, Object?>>();
    expect(restoredRows.single['deleted_at'], '2026-02-01T00:00:00.000Z');
  });
}
