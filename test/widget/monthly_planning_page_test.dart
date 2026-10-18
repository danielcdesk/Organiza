import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/monthly_planning_page.dart';

void main() {
  testWidgets('ocultar valores também protege indicadores percentuais',
      (tester) async {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MonthlyPlanningPage(store: store, hideValues: true)))));
    await tester.scrollUntilVisible(
        find.textContaining('Comprometimento essencial:'), 150);
    expect(find.text('Comprometimento essencial: ••••'), findsOneWidget);
  });
  testWidgets('reserva mostra alvo e saldo informado sem contar mês incompleto',
      (tester) async {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 10, 18)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final category = store.financeCategories.firstWhere((item) =>
        item.name == 'Alimentação' && item.type == TransactionType.expense);
    store.setFinanceCategoryEssentiality(
        category.id, ExpenseEssentiality.essential);
    store.addTransaction(
        accountId: store.accounts.single.id,
        type: TransactionType.expense,
        amountInCents: 10000,
        description: 'Mercado',
        category: 'Alimentação',
        occurredOn: DateTime(2026, 9, 10));
    store.addTransaction(
        accountId: store.accounts.single.id,
        type: TransactionType.expense,
        amountInCents: 90000,
        description: 'Mês parcial',
        category: 'Alimentação',
        occurredOn: DateTime(2026, 10, 10));
    store.updateEmergencyReserveSettings(reserveBalanceInCents: 20000);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
      child: MonthlyPlanningPage(store: store, hideValues: false),
    ))));
    await tester.scrollUntilVisible(find.text('Meta de reserva'), 150);
    expect(find.text('R\$ 200,00'), findsWidgets);
    expect(find.text('R\$ 199,98'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Ajustar reserva'), 150);
    await tester.tap(find.text('Ajustar reserva'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir categorias do cálculo'), findsOneWidget);
  });
  testWidgets('mostra totais do mês e permite navegar sem alterar lançamentos',
      (tester) async {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 9, 20)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 0);
    final account = store.accounts.single.id;
    store.addTransaction(
        accountId: account,
        type: TransactionType.income,
        amountInCents: 100000,
        description: 'Salário',
        occurredOn: DateTime(2026, 9, 2));
    store.addTransaction(
        accountId: account,
        type: TransactionType.expense,
        amountInCents: 25000,
        description: 'Mercado',
        category: 'Alimentação',
        occurredOn: DateTime(2026, 9, 4));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
      child: MonthlyPlanningPage(store: store, hideValues: false),
    ))));
    expect(find.text('R\$ 1.000,00'), findsWidgets);
    expect(find.text('R\$ 250,00'), findsWidgets);
    expect(find.text('R\$ 750,00'), findsWidgets);
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 0,00'), findsWidgets);
    expect(store.transactions, hasLength(2));
  });
}
