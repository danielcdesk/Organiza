import 'financial_planning.dart';

class EmergencyReserve {
  const EmergencyReserve({required this.averageMonthlyEssentialsInCents,
    required this.targetInCents});

  final int averageMonthlyEssentialsInCents;
  final int targetInCents;
}

List<DateTime> previousCompleteMonths(DateTime today, {int count = 3}) => [
  for (var offset = count; offset >= 1; offset--)
    DateTime.utc(today.year, today.month - offset),
];

EmergencyReserve calculateEmergencyReserve({
  required List<MonthlyFinancialPlan> completeMonths,
  int targetMonths = 6,
}) {
  if (targetMonths < 1 || targetMonths > 120) {
    throw ArgumentError('Informe entre 1 e 120 meses para a reserva.');
  }
  final total = completeMonths.fold<int>(0,
      (sum, plan) => sum + plan.reserveEligibleEssentialsInCents);
  final average = completeMonths.isEmpty
      ? 0
      : (total + completeMonths.length ~/ 2) ~/ completeMonths.length;
  return EmergencyReserve(
    averageMonthlyEssentialsInCents: average,
    targetInCents: average * targetMonths,
  );
}

class FinancialHealthIndicators {
  const FinancialHealthIndicators({
    required this.savingsRateBasisPoints,
    required this.essentialIncomeRatioBasisPoints,
    required this.reserveProgressBasisPoints,
    required this.investmentsInCents,
  });
  final int savingsRateBasisPoints;
  final int essentialIncomeRatioBasisPoints;
  final int reserveProgressBasisPoints;
  final int investmentsInCents;
}

FinancialHealthIndicators calculateHealth({
  required MonthlyFinancialPlan plan,
  required int investmentsInCents,
  required int reserveBalanceInCents,
  required int reserveTargetInCents,
}) => FinancialHealthIndicators(
      savingsRateBasisPoints: plan.savingsRateBasisPoints,
      essentialIncomeRatioBasisPoints: plan.incomeInCents <= 0
          ? 0
          : plan.essentialExpensesInCents * 10000 ~/ plan.incomeInCents,
      reserveProgressBasisPoints: reserveTargetInCents <= 0
          ? 0
          : reserveBalanceInCents * 10000 ~/ reserveTargetInCents,
      investmentsInCents: investmentsInCents,
    );
