import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/domain/credit_card_rules.dart';
import 'package:organiza/presentation/cards_page.dart';
import 'package:organiza/presentation/organiza_theme.dart';

void main() {
  testWidgets('marca parcelas no cartão e atualiza o progresso sem despesa',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime(2026, 9, 29, 12);
    final store = OrganizaStore.inMemory(clock: Clock.fixed(now));
    addTearDown(store.dispose);
    store.addAccount('Principal', 100000);
    store.addCreditCard(
      name: 'Principal',
      brand: CardBrand.visa,
      lastFour: '4242',
      limitInCents: 500000,
      closingDay: 28,
      dueDay: 17,
      colorValue: 0xFF245943,
    );
    store.addCardPurchase(
      cardId: store.creditCards.single.id,
      description: 'Notebook',
      amountInCents: 120000,
      installments: 3,
    );
    final balance = store.balance;
    expect(
      CreditCardRules.currentCyclePurchases(
        store.creditCards.single,
        store.cardPurchases,
        now,
      ),
      isNotEmpty,
    );

    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.dark(),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) => CardsPage(
            store: store,
            hideValues: false,
            onAddCard: () {},
            onAddPurchase: (_) {},
            onManageInstallments: (purchase) async {
              final paid = await showDialog<Set<int>>(
                context: tester.element(find.byType(CardsPage)),
                builder: (_) => CardInstallmentPaymentsDialog(
                  purchase: purchase,
                  hideValues: false,
                ),
              );
              if (paid != null) {
                store.setCardPurchaseInstallmentsPaid(purchase.id, paid);
              }
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('0 pagas · 3 restantes'), findsOneWidget);
    expect(find.text('Pague suas faturas na seção acima.'), findsOneWidget);
    await tester.tap(find.text('Gerenciar parcelas'));
    await tester.pumpAndSettle();
    expect(find.text('Parcela 1/3'), findsOneWidget);
    await tester.tap(find.text('Parcela 1/3'));
    await tester.tap(find.text('Parcela 3/3'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('2 pagas · 1 restantes'), findsOneWidget);
    expect(store.transactions, isEmpty);
    expect(store.balance, balance);
  });

  testWidgets('compras antigas ficam acessíveis para revisar parcelas',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime(2025, 9, 29, 12);
    final store = OrganizaStore.inMemory(clock: Clock(() => now));
    addTearDown(store.dispose);
    store.addCreditCard(
      name: 'Principal',
      brand: CardBrand.visa,
      lastFour: '4242',
      limitInCents: 500000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xFF245943,
    );
    store.addCardPurchase(
      cardId: store.creditCards.single.id,
      description: 'Notebook antigo',
      amountInCents: 120000,
      installments: 3,
    );
    now = DateTime(2026, 9, 29, 12);

    await tester.pumpWidget(MaterialApp(
      theme: OrganizaTheme.dark(),
      home: Scaffold(
        body: CardsPage(
          store: store,
          hideValues: false,
          onAddCard: () {},
          onAddPurchase: (_) {},
          onManageInstallments: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma compra nesta fatura'), findsOneWidget);
    await tester.tap(find.text('Ver histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Notebook antigo'), findsOneWidget);
    expect(find.text('Gerenciar parcelas'), findsOneWidget);
    expect(find.text('3 parcelas'), findsOneWidget);
  });
}
