import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/presentation/reports_page.dart';

void main() {
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
