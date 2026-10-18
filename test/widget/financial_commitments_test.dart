import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/financial_commitments_page.dart';

void main() {
  testWidgets('dívida aparece e permite confirmar parcela', (tester) async {
    final store = OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 9, 10)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 200000);
    store.addDebt(name: 'Empréstimo', principalInCents: 100000,
      monthlyInterestBasisPoints: 100, installmentAmountInCents: 10000,
      firstDueOn: DateTime(2026, 9, 10), installments: 12,
      accountId: store.accounts.single.id);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: FinancialCommitmentsPage(store: store, hideValues: false),
    ))));
    expect(find.text('Empréstimo'), findsOneWidget);
    await tester.tap(find.byTooltip('Registrar parcela'));
    await tester.pumpAndSettle();
    expect(store.debtPayments, hasLength(1));
    expect(store.balance, 190000);
  });
}
