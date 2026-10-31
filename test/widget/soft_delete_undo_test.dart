import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/organiza_app.dart';

Future<void> _openPage(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Abrir navegação'));
  await tester.pumpAndSettle();
  final item = find.descendant(
    of: find.byType(Drawer),
    matching: find.text(label),
  );
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> _confirmDelete(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Excluir').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desfaz exclusão de tarefa e transação', (tester) async {
    tester.view.physicalSize = const Size(390, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.saveProfile(name: 'Pessoa teste', incomeInCents: 0);
    store.addAccount('Principal', 100000);
    store.addTask('Revisar orçamento');
    store.addTransaction(
      accountId: store.accounts.single.id,
      type: TransactionType.expense,
      amountInCents: 1000,
      description: 'Café',
    );
    await tester.pumpWidget(OrganizaApp(store: store));
    await tester.pumpAndSettle();

    await _openPage(tester, 'Organização');
    await tester.tap(find.byTooltip('Excluir tarefa'));
    await tester.pumpAndSettle();
    await _confirmDelete(tester);
    expect(store.tasks, isEmpty);
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(store.tasks.single.title, 'Revisar orçamento');

    await _openPage(tester, 'Finanças');
    await tester.tap(find.byTooltip('Ações do lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir lançamento'));
    await tester.pumpAndSettle();
    await _confirmDelete(tester);
    expect(store.transactions, isEmpty);
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(store.transactions.single.description, 'Café');
    expect(tester.takeException(), isNull);
  });

  testWidgets('desfaz exclusão de item de compras', (tester) async {
    tester.view.physicalSize = const Size(390, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.saveProfile(name: 'Pessoa teste', incomeInCents: 0);
    store.addAccount('Principal', 100000);
    store.addShoppingItem(name: 'Fones', quantity: 1);
    await tester.pumpWidget(OrganizaApp(store: store));
    await tester.pumpAndSettle();

    await _openPage(tester, 'Lista de desejos');
    await tester.tap(find.byTooltip('Ações de Fones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    await _confirmDelete(tester);
    expect(store.shoppingItems, isEmpty);
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(store.shoppingItems.single.name, 'Fones');
    expect(tester.takeException(), isNull);
  });
}
