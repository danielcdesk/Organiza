import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/dialogs.dart';
import 'package:organiza/presentation/dashboard_page.dart';
import 'package:organiza/presentation/organiza_app.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('quick actions preselect income and transfer at $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = OrganizaStore.inMemory();
      addTearDown(store.dispose);
      store.saveProfile(name: 'Pessoa teste', incomeInCents: 200000);
      store.addAccount('Conta A', 100000);
      store.addAccount('Conta B', 0);
      await tester.pumpWidget(OrganizaApp(store: store));
      await tester.pumpAndSettle();
      final dashboardScroll = find
          .descendant(
            of: find.byType(DashboardPage),
            matching: find.byType(Scrollable),
          )
          .first;

      await tester.scrollUntilVisible(find.text('Nova despesa'), 250,
          scrollable: dashboardScroll);
      await tester.tap(find.text('Nova despesa').first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<TransactionType>>(
              find.byType(DropdownButtonFormField<TransactionType>),
            )
            .initialValue,
        TransactionType.expense,
      );
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Nova receita'), 250,
          scrollable: dashboardScroll);
      await tester.tap(find.text('Nova receita').first);
      await tester.pumpAndSettle();
      expect(find.byType(TransactionDialog), findsOneWidget);
      if (width == 390) {
        final content = find.descendant(
          of: find.byType(TransactionDialog),
          matching: find.byWidgetPredicate(
              (widget) => widget is SizedBox && widget.width == 500),
        );
        expect(tester.widget<SizedBox>(content).height, lessThan(530));
      }
      expect(
        tester
            .widget<DropdownButtonFormField<TransactionType>>(
              find.byType(DropdownButtonFormField<TransactionType>),
            )
            .initialValue,
        TransactionType.income,
      );
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Transferir'), 250,
          scrollable: dashboardScroll);
      await tester.tap(find.text('Transferir').first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<TransactionType>>(
              find.byType(DropdownButtonFormField<TransactionType>),
            )
            .initialValue,
        TransactionType.transfer,
      );
      expect(find.text('Conta de destino'), findsOneWidget);
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Mais ações'), 250,
          scrollable: dashboardScroll);
      await tester.tap(find.text('Mais ações').first);
      await tester.pumpAndSettle();
      expect(find.text('Adicionar conta'), findsOneWidget);
      await tester.tap(find.text('Adicionar conta'));
      await tester.pumpAndSettle();
      expect(find.text('Salvar conta'), findsOneWidget);
    });
  }
}
