import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('renomear categoria preserva histórico e vínculo da divisão salarial',
      () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 1, 2, 12)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 10000);
    final category =
        store.addFinanceCategory('Mercado local', TransactionType.expense);
    store.addSalaryAllocationBucket(
      name: 'Compras locais',
      percent: 0,
      linkedCategories: ['Mercado local'],
    );
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Pão',
      category: 'Mercado local',
    );
    final balance = store.balance;

    store.renameFinanceCategory(category.id, 'Feira do mês');

    expect(store.transactions.single.category, 'Feira do mês');
    expect(
        store.salaryAllocationBuckets
            .firstWhere((item) => item.name == 'Compras locais')
            .linkedCategories,
        ['Feira do mês']);
    expect(store.balance, balance);
    store.archiveFinanceCategory(category.id);
    expect(
        store.financeCategories.any((item) => item.id == category.id), isFalse);
    expect(store.transactions.single.category, 'Feira do mês');
    final historical = store.transactions.single;
    store.updateTransaction(TransactionRecord(
      id: historical.id,
      accountId: historical.accountId,
      type: historical.type,
      amountInCents: historical.amountInCents,
      description: 'Pão revisto',
      category: historical.category,
      subcategory: historical.subcategory,
      occurredOn: historical.occurredOn,
      createdAt: historical.createdAt,
      isSettled: historical.isSettled,
    ));
    expect(store.transactions.single.description, 'Pão revisto');
  });

  test('renomear receita não altera divisão de despesa com mesmo nome', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 1, 2, 12)));
    addTearDown(store.dispose);
    store.addSalaryAllocationBucket(
      name: 'Lazer planejado',
      percent: 0,
      linkedCategories: ['Lazer'],
    );
    final income = store.addFinanceCategory('Lazer', TransactionType.income);
    store.renameFinanceCategory(income.id, 'Receita de lazer');
    expect(
        store.salaryAllocationBuckets
            .firstWhere((item) => item.name == 'Lazer planejado')
            .linkedCategories,
        ['Lazer']);
    store.archiveFinanceCategory(income.id);
    expect(
        () => store.addFinanceCategory(
            'Receita de lazer', TransactionType.income),
        throwsArgumentError);
  });
}
