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
    (int, String)? result;
    await tester.pumpWidget(MaterialApp(
        theme: OrganizaTheme.light(),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await showDialog<(int, String)>(
                          context: context,
                          builder: (_) => TransactionEditDialog(item: item));
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
    expect(result, (2550, 'Corrigido'));
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
