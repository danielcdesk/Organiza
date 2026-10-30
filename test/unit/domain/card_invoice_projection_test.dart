import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/balance_projection.dart';
import 'package:organiza/domain/models.dart';

void main() {
  final account = Account(
    id: 'account',
    name: 'Principal',
    openingBalanceInCents: 50000,
    createdAt: DateTime(2026, 2, 1),
  );
  final card = CreditCard(
    id: 'card',
    name: 'Cartão',
    brand: CardBrand.visa,
    lastFour: '1234',
    limitInCents: 100000,
    closingDay: 10,
    dueDay: 17,
    colorValue: 0xff000000,
    createdAt: DateTime(2026, 2, 1),
  );
  final purchase = CardPurchase(
    id: 'purchase',
    cardId: 'card',
    description: 'Livro',
    amountInCents: 10000,
    purchasedOn: DateTime(2026, 2, 5),
    installments: 1,
    createdAt: DateTime(2026, 2, 5),
  );

  test('fatura pendente afeta projeção no vencimento', () {
    final result = BalanceProjection.calculate(
      accounts: [account],
      transactions: const [],
      salaries: const [],
      creditCards: [card],
      cardPurchases: [purchase],
      clock: Clock.fixed(DateTime(2026, 2, 1)),
      horizonDays: 20,
    );
    expect(result.points[15].balanceInCents, 50000);
    expect(result.points[16].balanceInCents, 40000);
    expect(result.points[16].accountBalancesInCents['account'], 50000);
    expect(result.points[16].cardObligationsInCents, 10000);
  });

  test('pagamento antecipado reduz só o restante no vencimento', () {
    final paidOn = DateTime(2026, 2, 5);
    final result = BalanceProjection.calculate(
      accounts: [account],
      transactions: [
        TransactionRecord(
          id: 'transaction',
          accountId: 'account',
          type: TransactionType.expense,
          amountInCents: 4000,
          description: 'Pagamento',
          occurredOn: paidOn,
          createdAt: paidOn,
          systemType: TransactionSystemType.cardPayment,
        )
      ],
      salaries: const [],
      creditCards: [card],
      cardPurchases: [purchase],
      cardInvoices: [
        CardInvoice(
          id: 'invoice',
          cardId: 'card',
          referenceYear: 2026,
          referenceMonth: 2,
          closingOn: DateTime(2026, 2, 10),
          dueOn: DateTime(2026, 2, 17),
          status: CardInvoiceStatus.partiallyPaid,
          createdAt: paidOn,
          updatedAt: paidOn,
        )
      ],
      cardInvoicePayments: [
        CardInvoicePayment(
          id: 'payment',
          invoiceId: 'invoice',
          accountId: 'account',
          transactionId: 'transaction',
          amountInCents: 4000,
          paidOn: paidOn,
          createdAt: paidOn,
        )
      ],
      clock: Clock.fixed(DateTime(2026, 2, 6)),
      horizonDays: 15,
    );
    expect(result.points.first.balanceInCents, 46000);
    expect(result.points[11].balanceInCents, 40000);
    expect(result.points[11].cardObligationsInCents, 6000);
  });
}
