import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/application/organiza_store.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('pagamento parcial reduz saldo sem duplicar despesa por categoria', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 2, 5, 12)));
    addTearDown(store.dispose);
    store.addAccount('Principal', 50000);
    store.addCreditCard(
      name: 'Cartão',
      brand: CardBrand.visa,
      lastFour: '1234',
      limitInCents: 100000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xff000000,
    );
    final card = store.creditCards.single;
    store.addCardPurchase(
      cardId: card.id,
      description: 'Livro',
      amountInCents: 10001,
      installments: 1,
    );
    final account = store.accounts.single;
    final before = store.balance;
    store.payCardInvoice(
      cardId: card.id,
      referenceYear: 2026,
      referenceMonth: 2,
      accountId: account.id,
      amountInCents: 4000,
      paymentId: 'payment-1',
    );
    expect(store.balance, before - 4000);
    expect(store.transactions.single.systemType,
        TransactionSystemType.cardPayment);
    expect(store.expenses, 0);
    expect(store.cardInvoicePayments.single.amountInCents, 4000);
    expect(store.cardInvoices.single.status, CardInvoiceStatus.partiallyPaid);
    final systemTransactionId = store.transactions.single.id;
    expect(() => store.deleteTransaction(systemTransactionId),
        throwsArgumentError);
    expect(() => store.setTransactionSettled(systemTransactionId, false),
        throwsArgumentError);
    store.payCardInvoice(
      cardId: card.id,
      referenceYear: 2026,
      referenceMonth: 2,
      accountId: account.id,
      amountInCents: 4000,
      paymentId: 'payment-1',
    );
    expect(store.cardInvoicePayments, hasLength(1));
    expect(store.balance, before - 4000);
    expect(
        () => store.payCardInvoice(
              cardId: card.id,
              referenceYear: 2026,
              referenceMonth: 2,
              accountId: account.id,
              amountInCents: 6002,
              paymentId: 'too-much',
            ),
        throwsArgumentError);
    expect(store.cardInvoicePayments, hasLength(1));
    store.payCardInvoice(
      cardId: card.id,
      referenceYear: 2026,
      referenceMonth: 2,
      accountId: account.id,
      amountInCents: 6001,
      paymentId: 'payment-2',
    );
    expect(store.cardInvoices.single.status, CardInvoiceStatus.paid);
    expect(store.balance, before - 10001);
    store.reverseCardInvoicePayment('payment-2');
    expect(store.cardInvoices.single.status, CardInvoiceStatus.partiallyPaid);
    expect(store.balance, before - 4000);
    expect(store.cardInvoicePayments, hasLength(1));
  });

  test('compra antiga exige confirmação para alterar fatura fechada', () {
    final store =
        OrganizaStore.inMemory(clock: Clock.fixed(DateTime(2026, 2, 5, 12)));
    addTearDown(store.dispose);
    store.addCreditCard(
      name: 'Cartão',
      brand: CardBrand.visa,
      lastFour: '1234',
      limitInCents: 100000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xff000000,
    );
    final cardId = store.creditCards.single.id;
    expect(
        () => store.addCardPurchase(
              cardId: cardId,
              description: 'Compra antiga',
              amountInCents: 1000,
              installments: 1,
              purchasedOn: DateTime(2026, 1, 5),
            ),
        throwsArgumentError);
    expect(store.cardPurchases, isEmpty);
    store.addCardPurchase(
      cardId: cardId,
      description: 'Compra antiga',
      amountInCents: 1000,
      installments: 1,
      purchasedOn: DateTime(2026, 1, 5),
      allowClosedInvoiceChange: true,
    );
    expect(store.cardPurchases.single.purchasedOn, DateTime(2026, 1, 5));
  });
}
