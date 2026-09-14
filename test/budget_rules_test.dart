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
}
