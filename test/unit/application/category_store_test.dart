import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('renomear categoria preserva histórico e vínculo da divisão salarial', () {
    final store = OrganizaStore.inMemory(
        clock: Clock.fixed(DateTime(2026, 1, 2, 12)));
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
    expect(store.salaryAllocationBuckets
        .firstWhere((item) => item.name == 'Compras locais')
        .linkedCategories, ['Feira do mês']);
    expect(store.balance, balance);
    store.archiveFinanceCategory(category.id);
    expect(store.financeCategories.any((item) => item.id == category.id), isFalse);
    expect(store.transactions.single.category, 'Feira do mês');
  });
}
