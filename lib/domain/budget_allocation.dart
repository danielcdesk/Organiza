import 'models.dart';

/// Base de orçamento derivada da renda do perfil, sem criar outro lançamento.
class BudgetAllocationBase {
  const BudgetAllocationBase({
    required this.essentialsInCents,
    required this.goalsInCents,
    required this.freeInCents,
  });

  final int essentialsInCents;
  final int goalsInCents;
  final int freeInCents;

  int get totalInCents =>
      essentialsInCents + goalsInCents + freeInCents;

  factory BudgetAllocationBase.fromIncome({
    required int incomeInCents,
    required SalaryAllocation allocation,
  }) {
    if (incomeInCents < 0) {
      throw ArgumentError.value(incomeInCents, 'incomeInCents');
    }
    final essentials = incomeInCents * allocation.essentialsPercent ~/ 100;
    final goals = incomeInCents * allocation.goalsPercent ~/ 100;
    return BudgetAllocationBase(
      essentialsInCents: essentials,
      goalsInCents: goals,
      freeInCents: incomeInCents - essentials - goals,
    );
  }
}
