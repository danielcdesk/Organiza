import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/organiza_app.dart';
import 'package:organiza/presentation/shared_widgets.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('abre os módulos financeiros principais sem overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = OrganizaStore.inMemory();
    addTearDown(store.dispose);
    store.addAccount(
      'Conta principal',
      485000,
      institution: AccountInstitution.nubank,
    );
    final accountId = store.accounts.first.id;
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.income,
      amountInCents: 320000,
      description: 'Salário',
      category: 'Outros',
    );
    store.addTransaction(
      accountId: accountId,
      type: TransactionType.expense,
      amountInCents: 127900,
      description: 'Despesas do mês',
      category: 'Alimentação',
    );
    store.addTask('Revisar o orçamento de setembro');
    store.addShoppingItem(
      name: 'Notebook para estudos',
      quantity: 1,
      estimatedUnitPriceInCents: 350000,
      priority: ShoppingPriority.high,
    );
    store.addCreditCard(
      name: 'Cartão principal',
      brand: CardBrand.mastercard,
      lastFour: '8421',
      limitInCents: 850000,
      closingDay: 18,
      dueDay: 25,
      colorValue: 0xFF245943,
    );
    store.addCardPurchase(
      cardId: store.creditCards.first.id,
      description: 'Mercado',
      amountInCents: 32490,
      installments: 1,
    );
    store.addInvestment(
      name: 'Tesouro Selic 2029',
      type: InvestmentType.fixedIncome,
      investedAmountInCents: 100000,
      currentValueInCents: 102400,
      fixedIncomeType: FixedIncomeType.treasurySelic,
      institutionName: 'Tesouro Direto',
      maturityDate: DateTime(2029, 3, 1),
    );
    store.addBudget(category: 'Alimentação', limitInCents: 250000);
    store.addSubscription(
        name: 'Streaming',
        amountInCents: 3990,
        billingDay: 15,
        category: 'Lazer');
    store.addFinancialGoal(
      name: 'Reserva de emergência',
      targetInCents: 1200000,
      initialSavedInCents: 360000,
      deadline: DateTime(2027, 6, 30),
    );

    final screenshotKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: screenshotKey,
        child: OrganizaApp(store: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumo financeiro'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final output = Directory('build/qa')..createSync(recursive: true);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-dashboard.png'),
    );

    await tester.tap(find.text('Finanças').first);
    await tester.pumpAndSettle();
    expect(find.text('Movimentações'), findsOneWidget);
    expect(find.text('Despesas do mês'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Nova transação'));
    await tester.pumpAndSettle();
    expect(find.text('Tipo de lançamento'), findsOneWidget);
    expect(find.text('Conta principal'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-transaction-dialog.png'),
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contas').first);
    await tester.pumpAndSettle();
    expect(find.text('Nubank'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-accounts.png'),
    );

    await tester.tap(find.text('Investimentos').first);
    await tester.pumpAndSettle();
    expect(find.text('Tesouro Selic 2029'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-investments.png'),
    );

    await tester.tap(find.text('Orçamentos').first);
    await tester.pumpAndSettle();
    expect(find.text('Orçamentos'), findsWidgets);
    expect(find.text('Alimentação'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-budgets.png'),
    );

    await tester.tap(find.text('Relatórios').first);
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final currentMonthLabel = '${monthName(now.month)} de ${now.year}';
    final previous = DateTime(now.year, now.month - 1);
    final previousMonthLabel =
        '${monthName(previous.month)} de ${previous.year}';
    expect(find.text('Evolução mensal'), findsOneWidget);
    expect(find.text(currentMonthLabel), findsOneWidget);
    expect(find.text('Visão realizada'), findsOneWidget);
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    expect(find.text(previousMonthLabel), findsOneWidget);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text(currentMonthLabel), findsOneWidget);
    await tester.tap(find.text('Com previsão'));
    await tester.pumpAndSettle();
    expect(find.text('Visão prevista'), findsOneWidget);
    await tester.tap(find.text('Realizado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(currentMonthLabel));
    await tester.pumpAndSettle();
    expect(find.text('Escolher período'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-reports.png'),
    );
    await tester.scrollUntilVisible(
      find.text('Mapa anual de gastos'),
      520,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Mapa anual de gastos'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-reports-roadmap.png'),
    );

    await tester.tap(find.text('Cartões').first);
    await tester.pumpAndSettle();
    expect(find.text('Acompanhe o ciclo atual sem armazenar dados sensíveis.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-cards.png'),
    );

    await tester.tap(find.text('Assinaturas').first);
    await tester.pumpAndSettle();
    expect(find.text('Assinaturas'), findsWidgets);
    expect(find.text('Streaming'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-subscriptions.png'),
    );

    await tester.tap(find.text('Planejamento').first);
    await tester.pumpAndSettle();
    expect(find.text('Salário identificado no mês'), findsOneWidget);
    expect(find.text('Distribuição sugerida'), findsOneWidget);
    expect(find.byTooltip('Excluir tarefa'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-planning.png'),
    );
    await tester.scrollUntilVisible(
      find.byTooltip('Excluir tarefa').last,
      460,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir tarefa').last);
    await tester.pumpAndSettle();
    expect(find.text('Excluir tarefa?'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(store.tasks, isEmpty);

    await tester.tap(find.text('Lista de desejos').first);
    await tester.pumpAndSettle();
    expect(find.text('Notebook para estudos'), findsOneWidget);
    expect(find.text('Valor estimado'), findsOneWidget);
    expect(find.byTooltip('Excluir item'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-shopping.png'),
    );
    await tester.tap(find.text('Adicionar item'));
    await tester.pumpAndSettle();
    expect(find.text('Preço por unidade (R\$)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir item'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir item?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(store.shoppingItems, hasLength(1));

    await tester.tap(find.text('Metas').first);
    await tester.pumpAndSettle();
    expect(find.text('Reserva de emergência'), findsOneWidget);
    expect(find.text('Registrar aporte'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _saveScreenshot(
      screenshotKey,
      File('${output.path}/organiza-goals.png'),
    );
  });
}

Future<void> _saveScreenshot(GlobalKey key, File output) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  await output.writeAsBytes(data!.buffer.asUint8List());
}
