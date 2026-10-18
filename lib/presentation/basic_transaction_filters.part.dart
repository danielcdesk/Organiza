part of 'basic_pages.dart';

class _TransactionFilters extends StatelessWidget {
  const _TransactionFilters({
    required this.filter,
    required this.onFilter,
    required this.pendingOnly,
    required this.onPending,
  });
  final TransactionType? filter;
  final ValueChanged<TransactionType?> onFilter;
  final bool pendingOnly;
  final ValueChanged<bool> onPending;
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: OrganizaDesignTokens.of(context).spaceSm,
        runSpacing: OrganizaDesignTokens.of(context).spaceSm,
        children: [
          FilterChip(
              avatar: filter == null
                  ? const Icon(Icons.check_circle_outline_rounded)
                  : null,
              label: const Text('Todas'),
              selected: filter == null,
              onSelected: (_) => onFilter(null)),
          FilterChip(
              avatar: const Icon(Icons.south_west_rounded),
              label: const Text('Receitas'),
              selected: filter == TransactionType.income,
              onSelected: (_) => onFilter(TransactionType.income)),
          FilterChip(
              avatar: const Icon(Icons.north_east_rounded),
              label: const Text('Despesas'),
              selected: filter == TransactionType.expense,
              onSelected: (_) => onFilter(TransactionType.expense)),
          FilterChip(
              avatar: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transferências'),
              selected: filter == TransactionType.transfer,
              onSelected: (_) => onFilter(TransactionType.transfer)),
          FilterChip(
              avatar: const Icon(Icons.schedule_rounded),
              label: const Text('Pendentes'),
              selected: pendingOnly,
              onSelected: onPending),
        ],
      );
}

class _TransactionFlowSummary extends StatelessWidget {
  const _TransactionFlowSummary(
      {required this.transactions, required this.hideValues});
  final List<TransactionRecord> transactions;
  final bool hideValues;
  @override
  Widget build(BuildContext context) {
    String money(int value) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(value);
    final incomes = transactions
        .where((t) => t.isSettled && t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amountInCents);
    final expenses = transactions
        .where((t) => t.isSettled && t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amountInCents);
    final metrics = [
      _FlowMetric(
          label: 'Entradas confirmadas',
          value: money(incomes),
          color: OrganizaDesignTokens.of(context).positive,
          icon: Icons.south_west_rounded),
      _FlowMetric(
          label: 'Saídas confirmadas',
          value: money(expenses),
          color: Theme.of(context).colorScheme.error,
          icon: Icons.north_east_rounded),
      _FlowMetric(
          label: 'Resultado do período',
          value: money(incomes - expenses),
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.account_balance_wallet_outlined,
          emphasized: true),
    ];
    final tokens = OrganizaDesignTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spaceLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outline),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(children: [
            for (var i = 0; i < metrics.length; i++) ...[
              metrics[i],
              if (i < metrics.length - 1) ...[
                SizedBox(height: tokens.spaceMd),
                const Divider(),
                SizedBox(height: tokens.spaceMd),
              ],
            ],
          ]);
        }
        return Row(children: [
          for (var i = 0; i < metrics.length; i++) ...[
            Expanded(
              flex: i == metrics.length - 1 ? 6 : 5,
              child: metrics[i],
            ),
            if (i < metrics.length - 1) _FlowDivider(),
          ],
        ]);
      }),
    );
  }
}

class _FlowMetric extends StatelessWidget {
  const _FlowMetric(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon,
      this.emphasized = false});
  final String label, value;
  final Color color;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: $value',
      child: Row(children: [
        Icon(icon, color: color),
        SizedBox(width: tokens.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceXs),
              Text(
                value,
                style: (emphasized
                        ? textTheme.headlineSmall
                        : textTheme.titleLarge)
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FlowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: OrganizaDesignTokens.of(context).hairlineThickness,
        height: OrganizaDesignTokens.of(context).minTapTarget,
        margin: EdgeInsets.symmetric(
          horizontal: OrganizaDesignTokens.of(context).spaceMd,
        ),
        color: Theme.of(context).dividerColor,
      );
}
