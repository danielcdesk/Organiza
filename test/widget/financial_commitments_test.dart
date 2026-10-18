import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/financial_commitments_page.dart';

void main() {
  testWidgets('conta recorrente mostra vencimento e confirma valor estimado',
      (tester) async {
    final store = OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 9, 10)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 100000);
    store.addRecurringObligation(name: 'Energia', category: 'Moradia',
      accountId: store.accounts.single.id, estimatedAmountInCents: 12000,
      billingDay: 11, nextDueOn: DateTime(2026, 9, 11));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: FinancialCommitmentsPage(store: store, hideValues: false),
    ))));
    expect(find.text('Energia'), findsOneWidget);
    await tester.tap(find.byTooltip('Confirmar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar pagamento'), findsWidgets);
    await tester.tap(find.text('Confirmar pagamento').last);
    await tester.pumpAndSettle();
    expect(store.balance, 88000);
    await tester.tap(find.byTooltip('Desfazer conta confirmada'));
    await tester.pumpAndSettle();
    expect(store.balance, 100000);
  });
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
