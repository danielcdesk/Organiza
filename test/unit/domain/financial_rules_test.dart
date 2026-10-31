import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/financial_rules.dart';
import 'package:organiza/domain/models.dart';

void main() {
  final now = DateTime(2026, 9, 10);
  final primary = Account(
      id: 'a',
      name: 'Principal',
      openingBalanceInCents: 100000,
      createdAt: now);
  final reserve = Account(
      id: 'b', name: 'Reserva', openingBalanceInCents: 0, createdAt: now);

  test('saldo incorpora receita, despesa e transferência uma única vez', () {
    final items = [
      TransactionRecord(
          id: '1',
          accountId: 'a',
          type: TransactionType.income,
          amountInCents: 20000,
          description: 'Freela',
          occurredOn: now,
          createdAt: now),
      TransactionRecord(
          id: '2',
          accountId: 'a',
          type: TransactionType.expense,
          amountInCents: 15000,
          description: 'Mercado',
          occurredOn: now,
          createdAt: now),
      TransactionRecord(
          id: '3',
          accountId: 'a',
          destinationAccountId: 'b',
          type: TransactionType.transfer,
          amountInCents: 30000,
          description: 'Reserva',
          occurredOn: now,
          createdAt: now),
    ];
    expect(FinancialRules.accountBalance(primary, items), 75000);
    expect(FinancialRules.accountBalance(reserve, items), 30000);
    expect(FinancialRules.currentBalance([primary, reserve], items), 105000);
  });

  test('patrimônio agrupa moedas e respeita a inclusão por conta', () {
    final usd = Account(
      id: 'usd',
      name: 'Dólares',
      openingBalanceInCents: 25000,
      createdAt: now,
      currency: 'USD',
    );
    final excluded = Account(
      id: 'excluded',
      name: 'Fora do patrimônio',
      openingBalanceInCents: 99000,
      createdAt: now,
      includeInNetWorth: false,
    );
    expect(
      FinancialRules.accountBalancesByCurrencyForNetWorth(
          [primary, usd, excluded], const []),
      {'BRL': 100000, 'USD': 25000},
    );
  });

  test('saída de caixa inclui pagamento de cartão sem categorizá-lo de novo',
      () {
    final payment = TransactionRecord(
      id: 'card-payment',
      accountId: 'a',
      type: TransactionType.expense,
      amountInCents: 6000,
      description: 'Pagamento da fatura',
      occurredOn: now,
      createdAt: now,
      systemType: TransactionSystemType.cardPayment,
    );
    expect(
        FinancialRules.monthTotal([payment], now, TransactionType.expense), 0);
    expect(FinancialRules.settledCashOutflowTotal([payment]), 6000);
  });

  test('total mensal não mistura outro mês nem transferência', () {
    final items = [
      TransactionRecord(
          id: '1',
          accountId: 'a',
          type: TransactionType.expense,
          amountInCents: 1000,
          description: 'Setembro',
          occurredOn: now,
          createdAt: now),
      TransactionRecord(
          id: '2',
          accountId: 'a',
          type: TransactionType.expense,
          amountInCents: 4000,
          description: 'Agosto',
          occurredOn: DateTime(2026, 8, 31),
          createdAt: now),
      TransactionRecord(
          id: '3',
          accountId: 'a',
          destinationAccountId: 'b',
          type: TransactionType.transfer,
          amountInCents: 9000,
          description: 'Transferência',
          occurredOn: now,
          createdAt: now),
    ];
    expect(
        FinancialRules.monthTotal(items, now, TransactionType.expense), 1000);
  });

  test('valores inválidos não entram na regra financeira', () {
    expect(FinancialRules.isValidAmount(0), isFalse);
    expect(FinancialRules.isValidAmount(-1), isFalse);
    expect(FinancialRules.isValidAmount(100), isTrue);
  });
}
