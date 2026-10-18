part of 'dashboard_page.dart';

class _DesktopQuickActions extends StatelessWidget {
  const _DesktopQuickActions({required this.actions});

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return Semantics(
      container: true,
      label: 'Ações rápidas',
      child: Column(
        key: const Key('desktop-quick-actions'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ações rápidas', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: tokens.spaceMd),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 4 : 2;
              final spacing = tokens.spaceMd;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final action in actions)
                    SizedBox(
                      width: itemWidth,
                      child: _DesktopQuickAction(action: action),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DesktopQuickAction extends StatelessWidget {
  const _DesktopQuickAction({required this.action});

  final QuickActionItem action;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final color = switch (action.tone) {
      QuickActionTone.positive => tokens.positive,
      QuickActionTone.neutral => tokens.neutral,
      QuickActionTone.brand => Theme.of(context).colorScheme.primary,
    };
    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      child: OutlinedButton.icon(
        key: ValueKey('desktop-action-${action.label}'),
        onPressed: action.onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: color,
          minimumSize: Size.fromHeight(
            tokens.minTapTarget + tokens.spaceSm,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMd,
            vertical: tokens.spaceSm,
          ),
        ),
        icon: Icon(action.icon),
        label: Text(
          action.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class _MonthlySnapshot extends StatelessWidget {
  const _MonthlySnapshot({
    required this.incomeInCents,
    required this.expenseInCents,
    required this.pendingExpenseInCents,
    required this.hideValues,
  });

  final int incomeInCents;
  final int expenseInCents;
  final int pendingExpenseInCents;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final result = incomeInCents - expenseInCents;
    final resultColor = result > 0
        ? tokens.positive
        : result < 0
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface;
    final metrics = [
      _SnapshotMetricData(
        icon: Icons.south_west_rounded,
        label: 'Entradas',
        context: 'recebidas no mês',
        value: hideValues
            ? '••••••'
            : FinancialRules.formatBrl(incomeInCents, signed: true),
        color: tokens.positive,
      ),
      _SnapshotMetricData(
        icon: Icons.north_east_rounded,
        label: 'Saídas',
        context: 'pagas no mês',
        value:
            hideValues ? '••••••' : FinancialRules.formatBrl(-expenseInCents),
        color: Theme.of(context).colorScheme.error,
      ),
      _SnapshotMetricData(
        icon: result >= 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        label: 'Resultado',
        context: 'entradas menos saídas',
        value: hideValues
            ? '••••••'
            : FinancialRules.formatBrl(result, signed: true),
        color: resultColor,
      ),
      _SnapshotMetricData(
        icon: Icons.schedule_rounded,
        label: 'Compromissos',
        context: 'pendentes até o fim do mês',
        value: hideValues
            ? '••••••'
            : FinancialRules.formatBrl(pendingExpenseInCents),
        color: tokens.warning,
      ),
    ];
    return HairlineSection(
      title: 'Movimento do mês',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
          final columns = largeText || constraints.maxWidth < 620 ? 2 : 4;
          final spacing = tokens.spaceMd;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            key: const Key('desktop-month-summary'),
            spacing: spacing,
            runSpacing: tokens.spaceLg,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: itemWidth,
                  child: _SnapshotMetric(data: metric),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SnapshotMetricData {
  const _SnapshotMetricData({
    required this.icon,
    required this.label,
    required this.context,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String context;
  final String value;
  final Color color;
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({required this.data});

  final _SnapshotMetricData data;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return Semantics(
      label: '${data.label}: ${data.value}. ${data.context}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(data.icon, color: data.color),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: Text(
                    data.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              data.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: data.color,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(height: tokens.spaceXs),
            Text(
              data.context,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsOverview extends StatelessWidget {
  const _AccountsOverview({
    required this.accounts,
    required this.transactions,
    required this.hideValues,
    required this.onOpenAccounts,
  });

  final List<Account> accounts;
  final List<TransactionRecord> transactions;
  final bool hideValues;
  final VoidCallback onOpenAccounts;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final visibleAccounts = accounts.take(4).toList();
    return HairlineSection(
      title: 'Suas contas',
      trailing: TextButton(
        onPressed: onOpenAccounts,
        child: Text(accounts.length > 4
            ? 'Ver todas (${accounts.length})'
            : 'Ver todas'),
      ),
      child: visibleAccounts.isEmpty
          ? const _InlineEmpty(
              icon: Icons.account_balance_outlined,
              text: 'Adicione uma conta para acompanhar os saldos.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(1) > 1.5;
                final preferredColumns =
                    !largeText && constraints.maxWidth >= 900 ? 4 : 2;
                final columns = visibleAccounts.length < preferredColumns
                    ? visibleAccounts.length
                    : preferredColumns;
                final spacing = tokens.spaceMd;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  key: const Key('desktop-account-overview'),
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final account in visibleAccounts)
                      SizedBox(
                        width: itemWidth,
                        child: _AccountBalanceItem(
                          account: account,
                          balanceInCents: FinancialRules.accountBalance(
                            account,
                            transactions,
                          ),
                          hideValues: hideValues,
                          onPressed: onOpenAccounts,
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _AccountBalanceItem extends StatelessWidget {
  const _AccountBalanceItem({
    required this.account,
    required this.balanceInCents,
    required this.hideValues,
    required this.onPressed,
  });

  final Account account;
  final int balanceInCents;
  final bool hideValues;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final value =
        hideValues ? '••••••' : FinancialRules.formatBrl(balanceInCents);
    return Semantics(
      button: true,
      label: '${account.name}, saldo $value. Abrir contas',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.minTapTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
            child: Row(
              children: [
                InstitutionMark(
                  institution: account.institution,
                  customIconKey: account.customIconKey,
                  size: tokens.quickActionDiameter - tokens.spaceMd,
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: tokens.spaceXs),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
