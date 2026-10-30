import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/models.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.openInMemory());
  tearDown(() => database.close());

  test('nova categoria recebe ID e renomear atualiza histórico e orçamento',
      () {
    database.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 10000,
      createdAt: DateTime(2026, 1, 1),
    ));
    database.insertTransaction(TransactionRecord(
      id: 'transaction',
      accountId: 'account',
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Pão',
      category: 'Padaria',
      subcategory: 'Pães',
      occurredOn: DateTime(2026, 1, 2),
      createdAt: DateTime(2026, 1, 2),
    ));
    database.insertBudget(Budget(
      id: 'budget',
      category: 'Padaria',
      limitInCents: 5000,
      year: 2026,
      month: 1,
      createdAt: DateTime(2026, 1, 1),
    ));
    database.insertSubscription(Subscription(
      id: 'subscription',
      name: 'Clube',
      amountInCents: 200,
      billingDay: 10,
      category: 'Padaria',
      createdAt: DateTime(2026, 1, 1),
    ));

    final old = database.loadTransactions().single;
    expect(old.categoryId, isNotNull);
    expect(old.subcategoryId, isNotNull);
    expect(database.loadBudgets().single.categoryId, old.categoryId);
    expect(database.loadSubscriptions().single.categoryId, old.categoryId);

    database.renameFinanceCategory(old.categoryId!, 'Comida nova');

    expect(database.loadTransactions().single.category, 'Comida nova');
    expect(database.loadBudgets().single.category, 'Comida nova');
    expect(database.loadSubscriptions().single.category, 'Comida nova');
    expect(database.loadTransactions().single.amountInCents, 1000);
    database.validateIntegrity();
  });

  test('categoria arquivada some da seleção mas permanece no histórico', () {
    database.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 0,
      createdAt: DateTime(2026, 1, 1),
    ));
    database.insertFinanceCategory(FinanceCategory(
      id: 'archived',
      name: 'Lazer especial',
      type: TransactionType.expense,
      createdAt: DateTime(2026, 1, 1),
    ));
    database.insertTransaction(TransactionRecord(
      id: 'old',
      accountId: 'account',
      type: TransactionType.expense,
      amountInCents: 100,
      description: 'Cinema',
      category: 'Lazer especial',
      occurredOn: DateTime(2026, 1, 2),
      createdAt: DateTime(2026, 1, 2),
    ));
    database.archiveFinanceCategory('archived');
    expect(
        database.loadFinanceCategories().any((item) => item.id == 'archived'),
        isFalse);
    expect(database.loadTransactions().single.category, 'Lazer especial');
    final historical = database.loadTransactions().single;
    database.updateTransaction(TransactionRecord(
      id: historical.id,
      accountId: historical.accountId,
      type: historical.type,
      amountInCents: historical.amountInCents,
      description: 'Cinema revisto',
      category: historical.category,
      subcategory: historical.subcategory,
      categoryId: historical.categoryId,
      subcategoryId: historical.subcategoryId,
      occurredOn: historical.occurredOn,
      createdAt: historical.createdAt,
    ));
    expect(database.loadTransactions().single.description, 'Cinema revisto');
    expect(
      () => database.insertTransaction(TransactionRecord(
        id: 'new',
        accountId: 'account',
        type: TransactionType.expense,
        amountInCents: 100,
        description: 'Outro cinema',
        category: 'Lazer especial',
        occurredOn: DateTime(2026, 1, 3),
        createdAt: DateTime(2026, 1, 3),
      )),
      throwsArgumentError,
    );
    expect(
      () => database.insertTransaction(TransactionRecord(
        id: 'new-with-id',
        accountId: 'account',
        type: TransactionType.expense,
        amountInCents: 100,
        description: 'Outro cinema',
        category: 'Lazer especial',
        categoryId: 'archived',
        occurredOn: DateTime(2026, 1, 3),
        createdAt: DateTime(2026, 1, 3),
      )),
      throwsArgumentError,
    );
    database.validateIntegrity();
  });

  test('falha de escrita externa reverte categoria criada junto ao lançamento',
      () {
    database.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 0,
      createdAt: DateTime(2026, 1, 1),
    ));
    expect(
      () => database.transaction(() {
        database.insertTransaction(TransactionRecord(
          id: 'rolled-back',
          accountId: 'account',
          type: TransactionType.expense,
          amountInCents: 100,
          description: 'Teste',
          category: 'Temporária',
          occurredOn: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
        ));
        throw StateError('falha simulada');
      }),
      throwsStateError,
    );
    expect(database.loadTransactions(), isEmpty);
    expect(
        database
            .loadFinanceCategories()
            .any((item) => item.name == 'Temporária'),
        isFalse);
  });
}
