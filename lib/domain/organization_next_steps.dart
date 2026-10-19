enum OrganizationStepKind {
  income,
  distribution,
  overdue,
  pending,
  budget,
  complete
}

class OrganizationStep {
  const OrganizationStep(this.kind, this.title, this.description);

  final OrganizationStepKind kind;
  final String title;
  final String description;
}

List<OrganizationStep> buildOrganizationNextSteps({
  required int plannedIncomeInCents,
  required bool distributionConfigured,
  required int overdueCount,
  required int pendingCount,
  required int? budgetUsedPercent,
}) {
  final steps = <OrganizationStep>[];
  if (plannedIncomeInCents <= 0) {
    steps.add(const OrganizationStep(OrganizationStepKind.income,
        'Informe sua renda', 'Defina uma base para organizar o mês.'));
  } else if (!distributionConfigured) {
    steps.add(const OrganizationStep(OrganizationStepKind.distribution,
        'Distribua sua renda', 'Escolha quanto reservar para cada objetivo.'));
  }
  if (overdueCount > 0) {
    steps.add(OrganizationStep(
        OrganizationStepKind.overdue,
        'Resolva $overdueCount pendência${overdueCount == 1 ? '' : 's'} atrasada${overdueCount == 1 ? '' : 's'}',
        'Confira vencimentos e confirme pagamentos.'));
  } else if (pendingCount > 0) {
    steps.add(OrganizationStep(
        OrganizationStepKind.pending,
        'Acompanhe $pendingCount pendência${pendingCount == 1 ? '' : 's'}',
        'Veja o que ainda precisa ser pago neste mês.'));
  }
  if (budgetUsedPercent != null && budgetUsedPercent >= 80) {
    steps.add(OrganizationStep(
        OrganizationStepKind.budget,
        budgetUsedPercent >= 100
            ? 'Revise o orçamento excedido'
            : 'Revise o orçamento',
        '$budgetUsedPercent% do limite já foi usado.'));
  }
  if (steps.isEmpty) {
    steps.add(const OrganizationStep(OrganizationStepKind.complete,
        'Mês em dia', 'Continue acompanhando seus lançamentos.'));
  }
  return steps;
}
