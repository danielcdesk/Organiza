import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/basic_pages.dart';
import 'package:organiza/presentation/organiza_theme.dart';
import 'package:organiza/presentation/overview_widgets.dart';
import 'package:organiza/presentation/goals_page.dart';
import 'package:organiza/presentation/dialogs.dart';

void main() {
  testWidgets('edit dialog returns cents without changing other fields',
      (tester) async {
    final now = DateTime.now();
    final item = TransactionRecord(
        id: 'edit',
        accountId: 'a',
        type: TransactionType.expense,
        amountInCents: 1000,
        description: 'Original',
        occurredOn: now,
        createdAt: now);
    TransactionRecord? result;
    final account = Account(
        id: 'a', name: 'Conta', openingBalanceInCents: 0, createdAt: now);
    final category = FinanceCategory(
        id: 'category',
        name: 'Outros',
        type: TransactionType.expense,
        createdAt: now);
    final subcategory = FinanceSubcategory(
        id: 'subcategory',
        categoryId: category.id,
        name: 'Geral',
        createdAt: now);
    await tester.pumpWidget(MaterialApp(
        theme: OrganizaTheme.light(),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await showDialog<TransactionRecord>(
                          context: context,
                          builder: (_) => TransactionEditDialog(
                              clock: Clock.fixed(now),
                              item: item,
                              accounts: [account],
                              categories: [category],
                              subcategories: [subcategory]));
                    },
                    child: const Text('Editar'))))));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'NaN');
    await tester.tap(find.text('Salvar alteração'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um valor válido.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '25,50');
    await tester.enterText(find.byType(TextField).last, 'Corrigido');
    await tester.tap(find.text('Salvar alteração'));
    await tester.pumpAndSettle();
    expect(result?.amountInCents, 2550);
    expect(result?.description, 'Corrigido');
  });
  testWidgets('goals fit a compact viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: OrganizaTheme.light(),
        home: Scaffold(
            body: GoalsPage(
                store: store,
                hideValues: false,
                onAdd: () {},
                onContribute: (_) {},
                onDelete: (_) {}))));
    await tester.pumpAndSettle();
  });
  testWidgets('monthly filters, totals and all-period history agree',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Banco A', 0);
    final now = DateTime.now();
    store.addTransaction(
        accountId: store.accounts.first.id,
        type: TransactionType.expense,
        amountInCents: 1000,
        description: 'Compra atual',
        occurredOn: now);
    store.addTransaction(
        accountId: store.accounts.first.id,
        type: TransactionType.expense,
        amountInCents: 2000,
        description: 'Compra antiga',
        occurredOn: DateTime(now.year, now.month - 1, 1));
    await tester.pumpWidget(MaterialApp(
        theme: OrganizaTheme.light(),
        home: Scaffold(
            body: TransactionsPage(
                store: store,
                hideValues: false,
                onAdd: () {},
                onDelete: (_) {},
                onSettledChanged: (id, settled) {}))));
    await tester.pumpAndSettle();
    expect(find.text('Compra atual'), findsOneWidget);
    expect(find.text('Compra antiga'), findsNothing);
    await tester.tap(find.text('Todo o período'));
    await tester.pumpAndSettle();
    expect(find.text('Compra antiga'), findsOneWidget);
    expect(find.text('R\$ 30,00'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Compra antiga'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transaction sorting prioritizes amount across different dates',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Banco A', 0);
    final accountId = store.accounts.first.id;
    final now = DateTime.now();
    store.addTransaction(
        accountId: accountId,
        type: TransactionType.expense,
        amountInCents: 1000,
        description: 'Compra recente',
        occurredOn: now);
    store.addTransaction(
        accountId: accountId,
        type: TransactionType.expense,
        amountInCents: 5000,
        description: 'Compra mais cara',
        occurredOn: now.subtract(const Duration(days: 3)));

    await tester.pumpWidget(MaterialApp(
        theme: OrganizaTheme.dark(),
        home: Scaffold(
            body: TransactionsPage(
                store: store,
                hideValues: false,
                onAdd: () {},
                onDelete: (_) {},
                onSettledChanged: (_, __) {}))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mais recentes primeiro'));
    await tester.pumpAndSettle();

    final recentY = tester.getTopLeft(find.text('Compra recente')).dy;
    final expensiveY = tester.getTopLeft(find.text('Compra mais cara')).dy;
    expect(expensiveY, lessThan(recentY));
    expect(find.text('Maior valor primeiro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop finance workspace groups summary filters and history',
      (tester) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Conta principal', 100000);
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.income,
      amountInCents: 50000,
      description: 'Salário',
    );
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 12500,
      description: 'Mercado',
    );

    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.dark(),
      home: Scaffold(
        body: TransactionsPage(
          store: store,
          hideValues: false,
          onAdd: () {},
          onDelete: (_) {},
          onSettledChanged: (_, __) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Entradas confirmadas'), findsOneWidget);
    expect(find.text('Saídas confirmadas'), findsOneWidget);
    expect(find.text('Resultado do período'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.text('2 resultados'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop finance empty state offers the first transaction',
      (tester) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.dark(),
      home: Scaffold(
        body: TransactionsPage(
          store: store,
          hideValues: false,
          onAdd: () {},
          onDelete: (_) {},
          onSettledChanged: (_, __) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Seu histórico começa aqui'), findsOneWidget);
    expect(find.text('Registre uma receita, despesa ou transferência.'),
        findsOneWidget);
    expect(find.text('Nova transação'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirm pending payment and undo restore balance on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Minha conta', 10000);
    store.addTransaction(
        accountId: store.accounts.first.id,
        type: TransactionType.expense,
        amountInCents: 1000,
        description: 'Conta pendente');
    store.setTransactionSettled(store.transactions.first.id, false);
    await tester.pumpWidget(MaterialApp(
        theme: OrganizaTheme.light(),
        home: Scaffold(
            body: ListenableBuilder(
                listenable: store,
                builder: (context, child) => ListView(children: [
                      CashFlowWorkspace(
                          store: store,
                          hideValues: false,
                          onOpenTransactions: () {}),
                    ])))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Confirmar pagamento'));
    await tester.tap(find.byTooltip('Confirmar pagamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(store.balance, 9000);
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(store.balance, 10000);
    expect(store.transactions.single.isSettled, false);
    expect(tester.takeException(), isNull);
  });
}
