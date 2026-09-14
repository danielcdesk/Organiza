import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/credit_card_rules.dart';
import 'package:organiza/domain/models.dart';

void main() {
  final card = CreditCard(
    id: 'card-1',
    name: 'Principal',
    brand: CardBrand.visa,
    lastFour: '4242',
    limitInCents: 500000,
    closingDay: 10,
    dueDay: 17,
    colorValue: 0xFF245943,
    createdAt: DateTime(2026, 9, 1),
  );

  CardPurchase purchase(String id, DateTime date, int cents) => CardPurchase(
        id: id,
        cardId: card.id,
        description: id,
        amountInCents: cents,
        purchasedOn: date,
        installments: 1,
        createdAt: date,
      );

  test('ciclo fecha no mês atual antes do fechamento', () {
    expect(
      CreditCardRules.currentCycleClosingDate(card, DateTime(2026, 9, 5)),
      DateTime(2026, 9, 10),
    );
  });

  test('ciclo avança para o mês seguinte após o fechamento', () {
    expect(
      CreditCardRules.currentCycleClosingDate(card, DateTime(2026, 9, 11)),
      DateTime(2026, 10, 10),
    );
  });

  test('fatura considera apenas compras entre fechamentos', () {
    final purchases = [
      purchase('anterior', DateTime(2026, 8, 10), 10000),
      purchase('ciclo-1', DateTime(2026, 8, 11), 20000),
      purchase('ciclo-2', DateTime(2026, 9, 10), 30000),
      purchase('proximo', DateTime(2026, 9, 11), 40000),
    ];

    expect(
      CreditCardRules.currentInvoiceTotal(
          card, purchases, DateTime(2026, 9, 10)),
      50000,
    );
    expect(
      CreditCardRules.availableLimit(card, purchases, DateTime(2026, 9, 10)),
      450000,
    );
  });

  test('parcelamento distribui valor entre faturas e reserva o limite', () {
    final purchase = CardPurchase(
      id: 'parcelada',
      cardId: card.id,
      description: 'Notebook',
      amountInCents: 120000,
      purchasedOn: DateTime(2026, 8, 12),
      installments: 12,
      createdAt: DateTime(2026, 8, 12),
    );

    expect(
      CreditCardRules.currentInvoiceTotal(
          card, [purchase], DateTime(2026, 10, 5)),
      10000,
    );
    expect(
      CreditCardRules.outstandingBalance(
          card, [purchase], DateTime(2026, 10, 5)),
      110000,
    );
    expect(
      CreditCardRules.availableLimit(card, [purchase], DateTime(2026, 10, 5)),
      390000,
    );
  });
}
