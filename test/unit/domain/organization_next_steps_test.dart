import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/organization_next_steps.dart';

void main() {
  test('renda ausente é o primeiro passo', () {
    final steps = buildOrganizationNextSteps(
        plannedIncomeInCents: 0,
        distributionConfigured: false,
        overdueCount: 2,
        pendingCount: 3,
        budgetUsedPercent: 95);
    expect(steps.first.kind, OrganizationStepKind.income);
  });

  test('distribuição, pendências e orçamento seguem prioridade', () {
    final steps = buildOrganizationNextSteps(
        plannedIncomeInCents: 200000,
        distributionConfigured: false,
        overdueCount: 1,
        pendingCount: 2,
        budgetUsedPercent: 95);
    expect(
        steps.map((step) => step.kind),
        containsAllInOrder([
          OrganizationStepKind.distribution,
          OrganizationStepKind.overdue,
          OrganizationStepKind.budget,
        ]));
  });

  test('mês sem pendências mostra conclusão', () {
    final steps = buildOrganizationNextSteps(
        plannedIncomeInCents: 200000,
        distributionConfigured: true,
        overdueCount: 0,
        pendingCount: 0,
        budgetUsedPercent: null);
    expect(steps.single.kind, OrganizationStepKind.complete);
  });
}
