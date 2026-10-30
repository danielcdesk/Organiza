import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';
import 'package:organiza/domain/financial_rules.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('snapshot restaura fatura, pagamento e saldo de conta', () {
    final source = AppDatabase.openInMemory();
    addTearDown(source.close);
    final now = DateTime(2026, 2, 17);
    source.insertAccount(Account(
      id: 'account',
      name: 'Principal',
      openingBalanceInCents: 50000,
      createdAt: now,
    ));
    source.insertCreditCard(CreditCard(
      id: 'card',
      name: 'Cartão',
      brand: CardBrand.visa,
      lastFour: '1234',
      limitInCents: 100000,
      closingDay: 10,
      dueDay: 17,
      colorValue: 0xff000000,
      createdAt: now,
    ));
    source.insertCardPurchase(CardPurchase(
      id: 'purchase',
      cardId: 'card',
      description: 'Livro',
      amountInCents: 10000,
      purchasedOn: DateTime(2026, 2, 5),
      installments: 1,
      createdAt: now,
    ));
    source.insertCardInvoice(CardInvoice(
      id: 'invoice',
      cardId: 'card',
      referenceYear: 2026,
      referenceMonth: 2,
      closingOn: DateTime(2026, 2, 10),
      dueOn: now,
      status: CardInvoiceStatus.paid,
      createdAt: now,
      updatedAt: now,
    ));
    source.insertTransaction(TransactionRecord(
      id: 'transaction',
      accountId: 'account',
      type: TransactionType.expense,
      amountInCents: 10000,
      description: 'Pagamento da fatura',
      category: 'Pagamento de cartão',
      occurredOn: now,
      createdAt: now,
      systemType: TransactionSystemType.cardPayment,
    ));
    source.insertCardInvoicePayment(CardInvoicePayment(
      id: 'payment',
      invoiceId: 'invoice',
      accountId: 'account',
      transactionId: 'transaction',
      amountInCents: 10000,
      paidOn: now,
      createdAt: now,
    ));
    final before = FinancialRules.currentBalance(
        source.loadAccounts(), source.loadTransactions());
    final target = AppDatabase.openInMemory();
    addTearDown(target.close);
    target.restoreSnapshot(source.exportSnapshot());
    expect(target.loadCardInvoices().single.status, CardInvoiceStatus.paid);
    expect(
        target.loadCardInvoicePayments().single.transactionId, 'transaction');
    expect(target.loadTransactions().single.systemType,
        TransactionSystemType.cardPayment);
    expect(
        FinancialRules.currentBalance(
            target.loadAccounts(), target.loadTransactions()),
        before);
    target.validateIntegrity();
  });
}
