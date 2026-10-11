import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';
import 'package:organiza/presentation/cards_page.dart';

void main() {
  testWidgets('cartões mostra a compra e histórico da fatura', (tester) async {
    final store = OrganizaStore.inMemory(
      clock: Clock.fixed(DateTime(2026, 2, 20)),
    );
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
      description: 'Mercado',
      amountInCents: 12000,
      installments: 1,
      purchasedOn: DateTime(2026, 1, 5),
      category: 'Alimentação',
      subcategory: 'Mercado',
    );

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CardsPage(
      store: store,
      hideValues: false,
      onAddCard: () {},
      onAddPurchase: (_) {},
      onEditCard: (_) {},
      onDeleteCard: (_) {},
      onEditPurchase: (_) {},
      onDeletePurchase: (_) {},
      onPayInvoice: (_) {},
      onReverseInvoicePayment: (_) {},
    ))));

    await tester.scrollUntilVisible(find.text('Histórico de faturas'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Histórico de faturas'), findsOneWidget);
    expect(find.text('Fechada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
