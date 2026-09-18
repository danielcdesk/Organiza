import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/cash_flow_summary.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/application/organiza_store.dart';

void main() {
  test('editing a settled transfer preserves identity and consolidated balance',
      () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Origem', 10000);
    store.addAccount('Destino', 0);
    final origin = store.accounts.firstWhere((a) => a.name == 'Origem');
    final destination = store.accounts.firstWhere((a) => a.name == 'Destino');
    store.addTransaction(
        accountId: origin.id,
        destinationAccountId: destination.id,
        type: TransactionType.transfer,
        amountInCents: 1000,
        description: 'Transferência');
    final before = store.transactions.single;
    store.updateTransactionDetails(before.id, 2500, 'Ajuste');
    store.reload();
    final after = store.transactions.single;
    expect(after.id, before.id);
    expect(after.occurredOn, before.occurredOn);
    expect(after.destinationAccountId, destination.id);
    expect(after.amountInCents, 2500);
    expect(after.description, 'Ajuste');
    expect(store.balance, 10000);
    expect(() => store.updateTransactionDetails(before.id, 0, ''),
        throwsArgumentError);
    expect(store.transactions.single.amountInCents, 2500);
  });
  TransactionRecord item(
          String id, TransactionType type, int cents, DateTime due,
          {bool paid = false}) =>
      TransactionRecord(
          id: id,
          accountId: 'a',
          type: type,
          amountInCents: cents,
          description: id,
          occurredOn: due,
          createdAt: due,
          isSettled: paid);

  test('projection includes overdue, excludes paid, transfers and next month',
      () {
    final result = CashFlowSummary([
      item('past', TransactionType.expense, 100, DateTime(2026, 8, 1)),
      item('today', TransactionType.expense, 200, DateTime(2026, 9, 17)),
      item('income', TransactionType.income, 500, DateTime(2026, 9, 30)),
      item('next', TransactionType.expense, 999, DateTime(2026, 10, 1)),
      item('paid', TransactionType.expense, 777, DateTime(2026, 9, 2),
          paid: true),
      item('transfer', TransactionType.transfer, 888, DateTime(2026, 9, 2)),
    ], DateTime(2026, 9, 17, 15));
    expect(result.payable, 300);
    expect(result.receivable, 500);
    expect(result.overdueCount, 1);
    expect(result.projectedBalance(1000), 1200);
    expect(
        result.pending.map((e) => e.id), ['past', 'today', 'income', 'next']);
  });

  test('empty and year boundary do not create fictitious income', () {
    expect(CashFlowSummary([], DateTime(2026, 12, 31)).projectedBalance(-100),
        -100);
    final result = CashFlowSummary([
      item('year-end', TransactionType.expense, 120, DateTime(2026, 12, 31)),
      item('new-year', TransactionType.income, 400, DateTime(2027, 1, 1)),
    ], DateTime(2026, 12, 31));
    expect(result.projectedBalance(100), -20);
  });

  test('appearance and privacy survive store reload', () {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.saveThemePreference('dark');
    store.saveHideValuesPreference(true);
    store.reload();
    expect(store.themePreference, 'dark');
    expect(store.hideValuesPreference, true);
    expect(() => store.saveThemePreference('invalid'), throwsArgumentError);
    expect(store.themePreference, 'dark');
  });
}
