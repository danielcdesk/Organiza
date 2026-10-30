import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/card_invoice_rules.dart';
import 'package:organiza/domain/models.dart';

void main() {
  final card = CreditCard(
    id: 'card',
    name: 'Cartão',
    brand: CardBrand.visa,
    lastFour: '1234',
    limitInCents: 200000,
    closingDay: 10,
    dueDay: 5,
    colorValue: 0xff000000,
    createdAt: DateTime(2026, 1, 1),
  );
  final purchase = CardPurchase(
    id: 'purchase',
    cardId: 'card',
    description: 'Notebook',
    amountInCents: 10001,
    purchasedOn: DateTime(2026, 1, 11),
    installments: 3,
    createdAt: DateTime(2026, 1, 11),
  );

  test('fecha após a compra e vence no mês seguinte', () {
    final cycle = CardInvoiceRules.cycle(card, 2026, 2);
    expect(cycle.closingOn, DateTime(2026, 2, 10));
    expect(cycle.dueOn, DateTime(2026, 3, 5));
    expect(CardInvoiceRules.totalInCents(card, [purchase], 2026, 2), 3334);
    expect(CardInvoiceRules.totalInCents(card, [purchase], 2026, 3), 3334);
    expect(CardInvoiceRules.totalInCents(card, [purchase], 2026, 4), 3333);
    expect(CardInvoiceRules.totalInCents(card, [purchase], 2026, 5), 0);
  });

  test('pagamento parcial e total determinam status e impedem excedente', () {
    final total = CardInvoiceRules.totalInCents(card, [purchase], 2026, 2);
    expect(
        CardInvoiceRules.status(
            total, 0, DateTime(2026, 2, 9), DateTime(2026, 2, 10)),
        CardInvoiceStatus.open);
    expect(
        CardInvoiceRules.status(
            total, 0, DateTime(2026, 2, 11), DateTime(2026, 2, 10)),
        CardInvoiceStatus.closed);
    expect(
        CardInvoiceRules.status(
            total, 1000, DateTime(2026, 2, 11), DateTime(2026, 2, 10)),
        CardInvoiceStatus.partiallyPaid);
    expect(
        CardInvoiceRules.status(
            total, total, DateTime(2026, 2, 11), DateTime(2026, 2, 10)),
        CardInvoiceStatus.paid);
    expect(() => CardInvoiceRules.remainingInCents(total, total + 1),
        throwsArgumentError);
  });
}
