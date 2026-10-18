import 'models.dart';

class MonthlyFinancialPlan {
  const MonthlyFinancialPlan({
    required this.incomeInCents,
    required this.essentialExpensesInCents,
    required this.nonEssentialExpensesInCents,
    required this.unclassifiedExpensesInCents,
    required this.reserveEligibleEssentialsInCents,
    required this.incomeBySourceInCents,
  });

  final int incomeInCents;
  final int essentialExpensesInCents;
  final int nonEssentialExpensesInCents;
  final int unclassifiedExpensesInCents;
  final int reserveEligibleEssentialsInCents;
  final Map<String, int> incomeBySourceInCents;

  int get totalExpensesInCents => essentialExpensesInCents +
      nonEssentialExpensesInCents + unclassifiedExpensesInCents;
  int get surplusInCents => incomeInCents - totalExpensesInCents;
  int get savingsRateBasisPoints =>
      incomeInCents <= 0 ? 0 : surplusInCents * 10000 ~/ incomeInCents;
}

MonthlyFinancialPlan summarize({
  required Iterable<TransactionRecord> transactions,
  required Iterable<FinanceCategory> categories,
  required DateTime month,
  required Set<String> excludedEssentialCategoryIds,
}) {
  final expenseCategories = <String, FinanceCategory>{
    for (final category in categories)
      if (category.type == TransactionType.expense)
        category.name.toLowerCase(): category,
  };
  var income = 0;
  var essential = 0;
  var nonEssential = 0;
  var unclassified = 0;
  var eligible = 0;
  final bySource = <String, int>{};
  for (final item in transactions) {
    if (item.occurredOn.year != month.year ||
        item.occurredOn.month != month.month ||
        item.type == TransactionType.transfer ||
        item.cardInvoiceId != null) {
      continue;
    }
    if (item.type == TransactionType.income) {
      income += item.amountInCents;
      final source = item.incomeSource?.trim();
      final key = source == null || source.isEmpty ? 'Sem fonte' : source;
      bySource.update(key, (value) => value + item.amountInCents,
          ifAbsent: () => item.amountInCents);
      continue;
    }
    final category = expenseCategories[item.category.toLowerCase()];
    final classification = item.essentialityOverride ??
        category?.essentiality ??
        ExpenseEssentiality.unclassified;
    switch (classification) {
      case ExpenseEssentiality.essential:
        essential += item.amountInCents;
        if (category == null ||
            !excludedEssentialCategoryIds.contains(category.id)) {
          eligible += item.amountInCents;
        }
      case ExpenseEssentiality.nonEssential:
        nonEssential += item.amountInCents;
      case ExpenseEssentiality.unclassified:
        unclassified += item.amountInCents;
    }
  }
  return MonthlyFinancialPlan(
    incomeInCents: income,
    essentialExpensesInCents: essential,
    nonEssentialExpensesInCents: nonEssential,
    unclassifiedExpensesInCents: unclassified,
    reserveEligibleEssentialsInCents: eligible,
    incomeBySourceInCents: Map.unmodifiable(bySource),
  );
}
