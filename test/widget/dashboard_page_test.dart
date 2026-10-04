import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/dashboard_page.dart';
import 'package:organiza/presentation/organiza_theme.dart';

void main() {
  testWidgets('dashboard vazio convida a criar conta e lançamento',
      (tester) async {
    final store = _store();
    addTearDown(store.dispose);
    await _pumpDashboard(tester, store);

    expect(find.text('Comece pelo básico'), findsOneWidget);
    expect(find.text('Criar primeira conta'), findsOneWidget);
    expect(find.text('Registrar primeiro lançamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard cheio mostra apenas o resumo essencial do mês',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _store();
    addTearDown(store.dispose);
    store.addAccount('Conta principal', 500000);
    final accountId = store.accounts.single.id;
    store.addCreditCard(
      name: 'Cartão principal',
      brand: CardBrand.mastercard,
      lastFour: '1234',
      limitInCents: 300000,
      closingDay: 5,
      dueDay: 10,
      colorValue: 0,
    );
    store.addCardPurchase(
      cardId: store.creditCards.single.id,
      description: 'Mercado no cartão',
      amountInCents: 8500,
      installments: 1,
    );
    store.addSubscription(
      name: 'Internet',
      amountInCents: 4990,
      billingDay: 2,
      category: 'Contas e serviços',
    );
    store.addBudget(
      category: 'Mercado',
      limitInCents: 100000,
      period: DateTime(2026, 9),
    );
    for (var index = 1; index <= 7; index++) {
      store.addTransaction(
        accountId: accountId,
        type: TransactionType.expense,
        amountInCents: 1000,
        description: 'Despesa $index',
        category: 'Mercado',
        occurredOn: DateTime(2026, 9, 29 - index),
      );
    }
    for (var index = 1; index <= 7; index++) {
      store.addTransaction(
        accountId: accountId,
        type: TransactionType.income,
        amountInCents: 5000,
        description: 'Entrada $index',
        occurredOn: DateTime(2026, 9, 29 - index),
      );
    }
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.expense,
      amountInCents: 3000,
      description: 'Conta atrasada',
      occurredOn: DateTime(2026, 9, 20),
    );
    store.setTransactionSettled(
      store.transactions
          .firstWhere((item) => item.description == 'Conta atrasada')
          .id,
      false,
    );

    await _pumpDashboard(tester, store);

    expect(find.text('Disponível no mês'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.textContaining('1 conta atrasada'), findsOneWidget);
    for (final label in [
      'Próxima fatura',
      'Próxima assinatura',
      'Orçamento do mês',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text(r'R$ 85,00'), findsOneWidget);
    expect(find.text(r'R$ 49,90'), findsOneWidget);
    expect(find.text(r'Restam R$ 930,00'), findsOneWidget);

    for (final label in [
      'Últimas despesas',
      'Últimas entradas',
      'Ver relatório mensal completo',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Despesa 6'), findsNothing);
    expect(find.text('Entrada 6'), findsNothing);
    expect(find.text('Movimento do mês'), findsNothing);
    expect(find.text('Últimos 6 meses'), findsNothing);
    expect(find.byTooltip('Nova transação'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ocultar valores esconde todos os valores monetários do painel',
      (tester) async {
    final store = _store();
    addTearDown(store.dispose);
    store.addAccount('Conta principal', 100000);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 2500,
      description: 'Café',
    );

    await _pumpDashboard(tester, store, hideValues: true);

    expect(find.text('••••••'), findsWidgets);
    expect(find.text(r'R$ 1.000,00'), findsNothing);
    expect(find.text(r'R$ 25,00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard não estoura com fonte em 200%', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    final store = _store();
    addTearDown(store.dispose);
    store.addAccount('Conta principal', 100000);
    await _pumpDashboard(tester, store);

    expect(tester.takeException(), isNull);
  });

  testWidgets('golden compacto do dashboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _store();
    addTearDown(store.dispose);
    store.addAccount('Conta principal', 100000);
    await _pumpDashboard(tester, store);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dashboard_compact.png'),
    );
  });

  testWidgets('golden expandido do dashboard', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _store();
    addTearDown(store.dispose);
    store.addAccount('Conta principal', 100000);
    await _pumpDashboard(tester, store);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dashboard_expanded.png'),
    );
  });
}

OrganizaStore _store() => OrganizaStore.inMemory(
      clock: Clock.fixed(DateTime(2026, 9, 29, 12)),
    );

Future<void> _pumpDashboard(
  WidgetTester tester,
  OrganizaStore store, {
  bool hideValues = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OrganizaTheme.dark(),
      home: Scaffold(
        body: DashboardPage(
          store: store,
          hideValues: hideValues,
          onNewTransaction: () {},
          onOpenCards: () {},
          onOpenTransactions: () {},
          onOpenGoals: () {},
          onOpenReports: () {},
          onNewAccount: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
