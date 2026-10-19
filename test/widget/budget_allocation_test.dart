import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/budgets_page.dart';

void main() {
  testWidgets('orçamento usa a distribuição da renda sem outro cadastro',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 10, 19)));
    addTearDown(store.dispose);
    store.saveProfile(name: 'Pessoa', incomeInCents: 200000);
    store.updateSalaryAllocation(
        essentialsPercent: 60, goalsPercent: 25, freePercent: 15);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BudgetsPage(
          store: store,
          onAdd: () {},
          onDelete: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Base do orçamento'), findsOneWidget);
    expect(find.text('R\$ 0,00 de R\$ 1.200,00'), findsOneWidget);
    expect(find.text('R\$ 500,00'), findsOneWidget);
    expect(find.text('R\$ 0,00 de R\$ 300,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
