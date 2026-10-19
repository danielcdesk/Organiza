import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/basic_pages.dart';

void main() {
  testWidgets('Organização usa renda do perfil sem simular recebimento',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 10, 18)));
    addTearDown(store.dispose);
    store.saveProfile(name: 'Pessoa', incomeInCents: 200000);
    store.addAccount('Principal', 0);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlanningPage(
          store: store,
          onAdd: () {},
          onDeleteTask: (_) async {},
          onAddBudget: () {},
          onDeleteBudget: (_) {},
          onCancelSalary: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Renda planejada do mês'));
    expect(find.text('R\$ 2.000,00'), findsWidgets);
    expect(find.text('Renda prevista'), findsOneWidget);
    expect(find.text('Receitas registradas'), findsOneWidget);
    expect(find.textContaining('não altera o saldo recebido'), findsOneWidget);
    expect(store.balance, 0);
    expect(store.transactions, isEmpty);
  });
}
