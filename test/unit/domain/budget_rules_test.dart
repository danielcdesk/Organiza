import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/financial_rules.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('consumo do orçamento considera categoria e mês', () {
    final now = DateTime(2026, 9, 10);
    final budget = Budget(
      id: 'b1',
      category: 'Alimentação',
      limitInCents: 100000,
      year: 2026,
      month: 9,
      createdAt: now,
    );
    final items = [
      TransactionRecord(
          id: '1',
          accountId: 'a',
          type: TransactionType.expense,
          amountInCents: 25000,
          description: 'Mercado',
          category: 'Alimentação',
          occurredOn: now,
          createdAt: now),
      TransactionRecord(
          id: '2',
          accountId: 'a',
          type: TransactionType.expense,
          amountInCents: 9000,
          description: 'Uber',
          category: 'Transporte',
          occurredOn: now,
          createdAt: now),
    ];
    expect(FinancialRules.budgetSpent(budget, items), 25000);
    expect(FinancialRules.budgetProgress(budget, items), .25);
  });

  test('compra parcelada consome orçamento na data da compra', () {
    final month = DateTime(2026, 1);
    final budget = Budget(
      id: 'budget',
      category: 'Livros',
      limitInCents: 30000,
      year: 2026,
      month: 1,
      createdAt: month,
    );
    final purchase = CardPurchase(
      id: 'purchase',
      cardId: 'card',
      description: 'Coleção',
      amountInCents: 30000,
      purchasedOn: DateTime(2026, 1, 5),
      installments: 3,
      createdAt: month,
      category: 'Livros',
    );
    final payment = TransactionRecord(
      id: 'payment',
      accountId: 'account',
      type: TransactionType.expense,
      amountInCents: 10000,
      description: 'Pagamento de fatura',
      category: 'Livros',
      occurredOn: DateTime(2026, 1, 17),
      createdAt: month,
      systemType: TransactionSystemType.cardPayment,
    );
    expect(FinancialRules.budgetSpent(budget, [payment], [purchase]), 30000);
  });
}
