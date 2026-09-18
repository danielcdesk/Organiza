import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/organiza_app.dart';

void main() {
  testWidgets('navegação mobile alcança todos os módulos', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount('Conta principal', 485000,
        institution: AccountInstitution.nubank);
    store.addTransaction(
      accountId: store.accounts.first.id,
      type: TransactionType.expense,
      amountInCents: 12790,
      description: 'Café',
      category: 'Alimentação',
    );
    store.addTask('Revisar orçamento');
    store.addShoppingItem(
      name: 'Fones',
      quantity: 1,
      estimatedUnitPriceInCents: 25000,
      priority: ShoppingPriority.normal,
    );
    store.addInvestment(
      name: 'Poupança',
      type: InvestmentType.fixedIncome,
      investedAmountInCents: 100000,
      currentValueInCents: 100500,
      fixedIncomeType: FixedIncomeType.savings,
      quotedRateBasisPoints: 50,
      quotedRatePeriod: InvestmentRatePeriod.monthly,
    );
    await tester.pumpWidget(
      OrganizaApp(store: store),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Resumo financeiro'), findsOneWidget);

    for (final label in [
      'Contas',
      'Cartões',
      'Organização',
      'Investimentos',
      'Metas',
      'Configurações',
      'Assinaturas',
      'Lista de desejos',
    ]) {
      await tester.tap(find.byTooltip('Abrir navegação'));
      await tester.pumpAndSettle();
      final drawerItem =
          find.descendant(of: find.byType(Drawer), matching: find.text(label));
      await tester.scrollUntilVisible(drawerItem, 180,
          scrollable: find
              .descendant(
                  of: find.byType(Drawer), matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      await tester.tap(drawerItem);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull, reason: label);
      expect(find.text(label), findsWidgets);
      if (label == 'Investimentos') {
        await tester.scrollUntilVisible(find.text('Valor atual'), 160,
            scrollable: find.byType(Scrollable).first);
        expect(find.text('Valor atual'), findsWidgets);
        await tester.ensureVisible(find.byTooltip('Ações de Poupança'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Ações de Poupança'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Editar posição'));
        await tester.pumpAndSettle();
        expect(find.text('Editar investimento'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      }
    }

    for (final label in ['Finanças', 'Organizar', 'Relatórios']) {
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Início')));
    await tester.pumpAndSettle();
    expect(find.text('Resumo financeiro'), findsOneWidget);
    await tester.tap(find.byTooltip('Abrir navegação'));
    await tester.pumpAndSettle();
    final settings = find.descendant(
        of: find.byType(Drawer), matching: find.text('Configurações'));
    await tester.scrollUntilVisible(settings, 180,
        scrollable: find
            .descendant(
                of: find.byType(Drawer), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    await tester.tap(settings);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-3-8')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metas').last);
    await tester.pumpAndSettle();
    expect(store.mobileQuickPages, [0, 1, 6, 7]);
    expect(
        find.descendant(
            of: find.byType(NavigationBar), matching: find.text('Metas')),
        findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Nova')));
    await tester.pumpAndSettle();
    expect(find.text('Nova transação'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
