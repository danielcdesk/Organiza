import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/budget_allocation.dart';
import 'package:organiza/domain/models.dart';

void main() {
  test('a distribuição vira base do orçamento sem perder centavos', () {
    final base = BudgetAllocationBase.fromIncome(
      incomeInCents: 10001,
      allocation: const SalaryAllocation(
        essentialsPercent: 50,
        goalsPercent: 30,
        freePercent: 20,
      ),
    );

    expect(base.essentialsInCents, 5000);
    expect(base.goalsInCents, 3000);
    expect(base.freeInCents, 2001);
    expect(base.totalInCents, 10001);
  });
}
