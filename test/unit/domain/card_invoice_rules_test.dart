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
    expect(CardInvoiceRules.cycle(card, 2026, 12).dueOn, DateTime(2027, 1, 5));
    final onClosing = CardPurchase(
      id: 'on-close',
      cardId: card.id,
      description: 'No fechamento',
      amountInCents: 1000,
      purchasedOn: DateTime(2026, 12, 10),
      installments: 1,
      createdAt: DateTime(2026, 12, 10),
    );
    final afterClosing = CardPurchase(
      id: 'after-close',
      cardId: card.id,
      description: 'Após fechamento',
      amountInCents: 1000,
      purchasedOn: DateTime(2026, 12, 11),
      installments: 1,
      createdAt: DateTime(2026, 12, 11),
    );
    expect(CardInvoiceRules.totalInCents(card, [onClosing], 2026, 12), 1000);
    expect(CardInvoiceRules.totalInCents(card, [afterClosing], 2026, 12), 0);
    expect(CardInvoiceRules.totalInCents(card, [afterClosing], 2027, 1), 1000);
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

  test('marcações antigas de parcelas não viram obrigação nem movimento novo',
      () {
    final legacyPurchase = CardPurchase(
      id: 'legacy',
      cardId: card.id,
      description: 'Compra antiga',
      amountInCents: 10001,
      purchasedOn: DateTime(2026, 1, 11),
      installments: 3,
      createdAt: DateTime(2026, 1, 11),
      paidInstallments: const {1},
    );
    expect(
      CardInvoiceRules.legacyPaidInCents(card, [legacyPurchase], 2026, 2),
      3334,
    );
    expect(
      CardInvoiceRules.remainingForPeriod(
        card,
        [legacyPurchase],
        2026,
        2,
        actualPaymentsInCents: 0,
      ),
      0,
    );
    expect(
      CardInvoiceRules.remainingForPeriod(
        card,
        [legacyPurchase],
        2026,
        2,
        actualPaymentsInCents: 5000,
      ),
      0,
    );
    expect(
      CardInvoiceRules.outstandingBalanceInCents(
        card,
        [legacyPurchase],
        invoices: const [],
        payments: const [],
        reference: DateTime(2026, 2, 11),
      ),
      6667,
    );
  });

  test('saldo pendente e limite incluem ciclos anteriores após virar o mês',
      () {
    final paidInvoice = CardInvoice(
      id: 'invoice-card-2026-2',
      cardId: card.id,
      referenceYear: 2026,
      referenceMonth: 2,
      closingOn: DateTime(2026, 2, 10),
      dueOn: DateTime(2026, 3, 5),
      status: CardInvoiceStatus.partiallyPaid,
      createdAt: DateTime(2026, 2, 10),
      updatedAt: DateTime(2026, 2, 11),
    );
    final payment = CardInvoicePayment(
      id: 'payment',
      invoiceId: paidInvoice.id,
      accountId: 'account',
      transactionId: 'transaction',
      amountInCents: 1000,
      paidOn: DateTime(2026, 2, 11),
      createdAt: DateTime(2026, 2, 11),
    );
    expect(
      CardInvoiceRules.outstandingBalanceInCents(
        card,
        [purchase],
        invoices: [paidInvoice],
        payments: [payment],
        reference: DateTime(2026, 3, 12),
      ),
      9001,
    );
  });
}
