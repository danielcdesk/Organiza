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
      name: 'Fones', quantity: 1,
      estimatedUnitPriceInCents: 25000,
      priority: ShoppingPriority.normal,
    );
    await tester.pumpWidget(
      OrganizaApp(store: store),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Resumo financeiro'), findsOneWidget);

    for (final label in [
      'Contas', 'Cartões', 'Orçamentos', 'Investimentos', 'Metas',
      'Configurações', 'Assinaturas', 'Lista de desejos',
    ]) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(label).last, 60,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull, reason: label);
    }

    for (final label in ['Finanças', 'Planejamento', 'Relatórios']) {
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Início')));
    await tester.pumpAndSettle();
    expect(find.text('Resumo financeiro'), findsOneWidget);
    await tester.tap(find.byTooltip('Nova transação'));
    await tester.pumpAndSettle();
    expect(find.text('Nova transação'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
