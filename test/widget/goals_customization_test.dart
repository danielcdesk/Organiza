import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/goals_page.dart';
import 'package:organiza/presentation/dialogs.dart';

void main() {
  testWidgets('formulário de edição da meta cabe no mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addFinancialGoal(
        name: 'Viagem',
        targetInCents: 100000,
        initialSavedInCents: 20000,
        note: 'Praia');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
          onPressed: () => showDialog<FinancialGoalInput>(
              context: context,
              builder: (_) => FinancialGoalDialog(
                  categories: store.goalCategories,
                  onCreateCategory: (_) {},
                  goal: store.financialGoals.single)),
          child: const Text('Abrir')),
    ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Editar meta'), findsOneWidget);
    expect(find.text('Salvar meta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('imagem de meta ausente usa ícone local e permite editar',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addFinancialGoal(
        name: 'Viagem',
        targetInCents: 100000,
        initialSavedInCents: 20000,
        iconKey: 'travel',
        note: 'Praia',
        imagePath: 'arquivo-inexistente.png');
    var edited = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GoalsPage(
      store: store,
      hideValues: false,
      onAdd: () {},
      onContribute: (_) {},
      onDelete: (_) {},
      onEdit: (_) => edited = true,
    ))));
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
    expect(find.text('Praia'), findsOneWidget);
    await tester.tap(find.byTooltip('Ações da meta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar meta'));
    expect(edited, isTrue);
    expect(tester.takeException(), isNull);
  });
}
