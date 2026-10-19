import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/reports_page.dart';

void main() {
  testWidgets('orçamento antigo aparece só no período dos relatórios',
      (tester) async {
    final store = OrganizaStore.inMemory(
        clock: Clock.fixed(DateTime(2026, 10, 18)));
    addTearDown(store.dispose);
    store.addBudget(category: 'Alimentação', limitInCents: 50000,
        period: DateTime(2026, 9));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ReportsPage(
      store: store, hideValues: false, onExport: (_, __) async {},
    ))));
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Orçamentos e faturas do período'),
        200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Alimentação'), findsWidgets);
  });
  testWidgets('indicadores de relatório são compactos e responsivos',
      (tester) async {
    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    for (final width in [320.0, 390.0, 600.0, 1024.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ReportsPage(
        store: store,
        hideValues: false,
        onExport: (_, __) async {},
      ))));
      await tester.pumpAndSettle();
      final card = find
          .ancestor(
              of: find.text('Entradas do mês'), matching: find.byType(Card))
          .first;
      expect(tester.getSize(card).height, lessThanOrEqualTo(110));
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
  testWidgets('relatórios mostram distribuição histórica verificável',
      (tester) async {
    var now = DateTime(2026, 10, 18);
    final store = OrganizaStore.inMemory(clock: Clock(() => now));
    addTearDown(store.dispose);
    store.updateSalaryAllocation(
        essentialsPercent: 60, goalsPercent: 25, freePercent: 15);
    now = DateTime(2026, 11, 1);
    store.updateSalaryAllocation(
        essentialsPercent: 50, goalsPercent: 30, freePercent: 20);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ReportsPage(
                store: store, hideValues: false, onExport: (_, __) async {}))));
    await tester.scrollUntilVisible(find.text('Distribuição planejada'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    expect(find.text('Essenciais 50%'), findsOneWidget);
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Distribuição planejada'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    expect(find.text('Essenciais 60%'), findsOneWidget);
  });
}
