import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/financial_health.dart';
import 'package:organiza/domain/financial_planning.dart';

void main() {
  MonthlyFinancialPlan month(int income, int essential, int eligible) =>
      MonthlyFinancialPlan(
        incomeInCents: income,
        essentialExpensesInCents: essential,
        nonEssentialExpensesInCents: 0,
        unclassifiedExpensesInCents: 0,
        reserveEligibleEssentialsInCents: eligible,
        incomeBySourceInCents: const {},
      );

  test('reserva usa média de três meses completos e multiplica sem perder centavos', () {
    final reserve = calculateEmergencyReserve(
      completeMonths: [month(10000, 10001, 10001), month(10000, 10002, 10002),
        month(10000, 10003, 10003)],
      targetMonths: 6,
    );
    expect(reserve.averageMonthlyEssentialsInCents, 10002);
    expect(reserve.targetInCents, 60012);
  });

  test('seleção civil ignora mês corrente inclusive fevereiro bissexto', () {
    final months = previousCompleteMonths(DateTime.utc(2028, 3, 1), count: 3);
    expect(months, [DateTime.utc(2027, 12), DateTime.utc(2028, 1),
      DateTime.utc(2028, 2)]);
  });

  test('indicadores tratam renda zero e sobra negativa', () {
    final health = calculateHealth(
      plan: month(1000, 1500, 1200),
      investmentsInCents: 200,
      reserveBalanceInCents: 600,
      reserveTargetInCents: 1200,
    );
    expect(health.savingsRateBasisPoints, -5000);
    expect(health.essentialIncomeRatioBasisPoints, 15000);
    expect(health.reserveProgressBasisPoints, 5000);
    expect(calculateHealth(plan: month(0, 100, 100),
      investmentsInCents: 0, reserveBalanceInCents: 0,
      reserveTargetInCents: 0).essentialIncomeRatioBasisPoints, 0);
  });
}
