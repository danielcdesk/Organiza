import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/financial_planning.dart';
import 'package:organiza/domain/models.dart';

void main() {
  final date = DateTime.utc(2026, 9, 10);
  TransactionRecord item(String id, TransactionType type, int cents,
          {String category = 'Outros',
          ExpenseEssentiality? override,
          String? source,
          DateTime? on}) =>
      TransactionRecord(
        id: id,
        accountId: 'a',
        destinationAccountId: type == TransactionType.transfer ? 'b' : null,
        type: type,
        amountInCents: cents,
        description: id,
        category: category,
        essentialityOverride: override,
        incomeSource: source,
        occurredOn: on ?? date,
        createdAt: date,
      );

  test('classifica despesas sem perder categoria antiga e ignora transferências',
      () {
    final summary = summarize(
      month: date,
      categories: [
        FinanceCategory(
          id: 'food',
          name: 'Alimentação',
          type: TransactionType.expense,
          essentiality: ExpenseEssentiality.essential,
          createdAt: date,
        ),
      ],
      transactions: [
        item('salary', TransactionType.income, 10001),
        item('food', TransactionType.expense, 2001,
            category: 'Alimentação'),
        item('legacy', TransactionType.expense, 300),
        item('override', TransactionType.expense, 401,
            category: 'Alimentação',
            override: ExpenseEssentiality.nonEssential),
        item('transfer', TransactionType.transfer, 9000),
        item('old', TransactionType.expense, 8000,
            on: DateTime.utc(2026, 8, 31)),
      ],
      excludedEssentialCategoryIds: const {},
    );
    expect(summary.incomeInCents, 10001);
    expect(summary.essentialExpensesInCents, 2001);
    expect(summary.nonEssentialExpensesInCents, 401);
    expect(summary.unclassifiedExpensesInCents, 300);
    expect(summary.surplusInCents, 7299);
    expect(summary.savingsRateBasisPoints, 7298);
  });

  test('receitas com e sem fonte somam e renda zero não divide por zero', () {
    final summary = summarize(
      month: date,
      categories: const [],
      transactions: [
        item('one', TransactionType.income, 700, source: 'Salário'),
        item('two', TransactionType.income, 300),
      ],
      excludedEssentialCategoryIds: const {},
    );
    expect(summary.incomeInCents, 1000);
    expect(summary.incomeBySourceInCents['Salário'], 700);
    expect(summary.incomeBySourceInCents['Sem fonte'], 300);
    expect(
      summarize(
        month: date,
        categories: const [],
        transactions: [item('bill', TransactionType.expense, 100)],
        excludedEssentialCategoryIds: const {},
      ).savingsRateBasisPoints,
      0,
    );
  });
}
