import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/cash_flow_summary.dart';
import '../domain/credit_card_rules.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'organiza_theme.dart';
import 'shared_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onNewTransaction,
    required this.onOpenCards,
    required this.onOpenTransactions,
    required this.onOpenGoals,
    required this.onOpenReports,
    required this.onNewAccount,
    this.onOpenAccounts,
    this.onOpenBudgets,
    this.onOpenSubscriptions,
    this.onToggleValues,
    this.onNewIncome,
    this.onTransfer,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onNewTransaction;
  final VoidCallback onOpenCards;
  final VoidCallback onOpenTransactions;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenReports;
  final VoidCallback onNewAccount;
  final VoidCallback? onOpenAccounts;
  final VoidCallback? onOpenBudgets;
  final VoidCallback? onOpenSubscriptions;
  final VoidCallback? onToggleValues;
  final VoidCallback? onNewIncome;
  final VoidCallback? onTransfer;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _month = _monthStart(widget.store.clock.now());
  var _tipDismissed = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final today = _dateOnly(widget.store.clock.now());
          final reference = _referenceForMonth(_month, today);
          final summary = CashFlowSummary(widget.store.transactions, _month);
          final available = widget.store.balance - summary.payable;
          final monthTransactions =
              _monthTransactions(widget.store.transactions, _month);
          final monthIncome = FinancialRules.monthTotal(
            monthTransactions,
            _month,
            TransactionType.income,
          );
          final monthExpense = FinancialRules.monthTotal(
            monthTransactions,
            _month,
            TransactionType.expense,
          );
          final expenses = _recentTransactions(
            monthTransactions,
            TransactionType.expense,
          );
          final incomes = _recentTransactions(
            monthTransactions,
            TransactionType.income,
          );
          final invoice = _nextInvoice(widget.store, reference);
          final subscription =
              _nextSubscription(widget.store.subscriptions, reference);
          final budget = _budgetSummary(widget.store, _month);
          final overdue = summary.pending
              .where((item) =>
                  item.type == TransactionType.expense &&
                  _dateOnly(item.occurredOn).isBefore(today))
              .toList();
          final hasData = widget.store.accounts.isNotEmpty ||
              widget.store.transactions.isNotEmpty ||
              widget.store.creditCards.isNotEmpty ||
              widget.store.subscriptions.isNotEmpty ||
              widget.store.budgets.isNotEmpty;

          final content = !hasData
              ? <Widget>[
                  _HeroSurface(
                    child: _DashboardHero(
                      available: _money(available),
                      current: _money(widget.store.balance),
                      hideValues: widget.hideValues,
                      hint: 'Adicione sua primeira conta para começar',
                    ),
                  ),
                  SizedBox(height: OrganizaDesignTokens.of(context).spaceXl),
                  _EmptyDashboard(
                    onNewAccount: widget.onNewAccount,
                    onNewTransaction: widget.onNewTransaction,
                  ),
                ]
              : compact
                  ? _mobileContent(
                      context,
                      available: available,
                      current: widget.store.balance,
                      invoice: invoice,
                      subscription: subscription,
                      budget: budget,
                      expenses: expenses,
                      incomes: incomes,
                      overdue: overdue,
                    )
                  : _desktopContent(
                      context,
                      available: available,
                      current: widget.store.balance,
                      invoice: invoice,
                      subscription: subscription,
                      budget: budget,
                      expenses: expenses,
                      incomes: incomes,
                      overdue: overdue,
                      monthIncome: monthIncome,
                      monthExpense: monthExpense,
                      pendingExpense: summary.payable,
                    );

          return FocusTraversalGroup(
            key: const Key('dashboard-focus-order'),
            policy: OrderedTraversalPolicy(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                compact ? 20 : 34,
                compact ? 18 : 28,
                compact ? 20 : 34,
                40,
              ),
              children: [
                _MonthToolbar(
                  month: _month,
                  compact: compact,
                  hideValues: widget.hideValues,
                  onPrevious: () =>
                      setState(() => _month = _shiftMonth(_month, -1)),
                  onNext: () => setState(() => _month = _shiftMonth(_month, 1)),
                  onToggleValues: widget.onToggleValues,
                  onNewTransaction: compact ? null : widget.onNewTransaction,
                ),
                SizedBox(height: OrganizaDesignTokens.of(context).spaceLg),
                ...content,
              ],
            ),
          );
        },
      );

  List<Widget> _mobileContent(
    BuildContext context, {
    required int available,
    required int current,
    required _NextInvoice? invoice,
    required _NextSubscription? subscription,
    required _BudgetSummary? budget,
    required List<TransactionRecord> expenses,
    required List<TransactionRecord> incomes,
    required List<TransactionRecord> overdue,
  }) {
    final tokens = OrganizaDesignTokens.of(context);
    return [
      _HeroSurface(
        child: _DashboardHero(
          available: _money(available),
          current: _money(current),
          hideValues: widget.hideValues,
        ),
      ),
      SizedBox(height: tokens.spaceXl),
      QuickActionGrid(actions: _quickActions()),
      if (overdue.isNotEmpty) ...[
        SizedBox(height: tokens.spaceLg),
        _OverdueNotice(
          count: overdue.length,
          totalInCents: overdue.fold(
            0,
            (total, item) => total + item.amountInCents,
          ),
          hideValues: widget.hideValues,
          onPressed: widget.onOpenTransactions,
        ),
      ],
      if (_showTip) ...[
        SizedBox(height: tokens.spaceLg),
        _Tip(
          onDismiss: () => setState(() => _tipDismissed = true),
          onAction: widget.onNewAccount,
        ),
      ],
      SizedBox(height: tokens.spaceXl),
      _EssentialsSection(
        invoice: invoice,
        subscription: subscription,
        budget: budget,
        cardStyle: true,
        hideValues: widget.hideValues,
        onOpenCards: widget.onOpenCards,
        onOpenSubscriptions: widget.onOpenSubscriptions ?? widget.onOpenReports,
        onOpenBudgets: widget.onOpenBudgets ?? widget.onOpenReports,
      ),
      SizedBox(height: tokens.spaceXl),
      _RecentSection(
        title: 'Últimas despesas',
        items: expenses,
        accounts: widget.store.accounts,
        hideValues: widget.hideValues,
        emptyText: 'Nenhuma despesa registrada neste mês.',
        onSeeAll: widget.onOpenTransactions,
      ),
      SizedBox(height: tokens.spaceXl),
      _RecentSection(
        title: 'Últimas entradas',
        items: incomes,
        accounts: widget.store.accounts,
        hideValues: widget.hideValues,
        emptyText: 'Nenhuma entrada registrada neste mês.',
        onSeeAll: widget.onOpenTransactions,
      ),
      SizedBox(height: tokens.spaceXl),
      _ReportLink(onPressed: widget.onOpenReports),
    ];
  }

  List<Widget> _desktopContent(
    BuildContext context, {
    required int available,
    required int current,
    required _NextInvoice? invoice,
    required _NextSubscription? subscription,
    required _BudgetSummary? budget,
    required List<TransactionRecord> expenses,
    required List<TransactionRecord> incomes,
    required List<TransactionRecord> overdue,
    required int monthIncome,
    required int monthExpense,
    required int pendingExpense,
  }) {
    final tokens = OrganizaDesignTokens.of(context);
    final hero = _HeroSurface(
      child: _DashboardHero(
        available: _money(available),
        current: _money(current),
        hideValues: widget.hideValues,
      ),
    );
    final financialOverview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hero,
        SizedBox(height: tokens.spaceXl),
        _MonthlySnapshot(
          incomeInCents: monthIncome,
          expenseInCents: monthExpense,
          pendingExpenseInCents: pendingExpense,
          hideValues: widget.hideValues,
        ),
      ],
    );
    final nextSteps = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdue.isNotEmpty) ...[
          _OverdueNotice(
            count: overdue.length,
            totalInCents: overdue.fold(
              0,
              (total, item) => total + item.amountInCents,
            ),
            hideValues: widget.hideValues,
            onPressed: widget.onOpenTransactions,
          ),
          SizedBox(height: tokens.spaceLg),
        ],
        _EssentialsSection(
          invoice: invoice,
          subscription: subscription,
          budget: budget,
          cardStyle: false,
          hideValues: widget.hideValues,
          onOpenCards: widget.onOpenCards,
          onOpenSubscriptions:
              widget.onOpenSubscriptions ?? widget.onOpenReports,
          onOpenBudgets: widget.onOpenBudgets ?? widget.onOpenReports,
        ),
        SizedBox(height: tokens.spaceLg),
        _ReportLink(onPressed: widget.onOpenReports),
      ],
    );
    final expensesSection = _RecentSection(
      title: 'Últimas despesas',
      items: expenses,
      accounts: widget.store.accounts,
      hideValues: widget.hideValues,
      emptyText: 'Nenhuma despesa registrada neste mês.',
      onSeeAll: widget.onOpenTransactions,
    );
    final incomesSection = _RecentSection(
      title: 'Últimas entradas',
      items: incomes,
      accounts: widget.store.accounts,
      hideValues: widget.hideValues,
      emptyText: 'Nenhuma entrada registrada neste mês.',
      onSeeAll: widget.onOpenTransactions,
    );
    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
          final useColumns = constraints.maxWidth >= 960 && !largeText;
          if (!useColumns) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hero,
                SizedBox(height: tokens.spaceXl),
                _MonthlySnapshot(
                  incomeInCents: monthIncome,
                  expenseInCents: monthExpense,
                  pendingExpenseInCents: pendingExpense,
                  hideValues: widget.hideValues,
                ),
                SizedBox(height: tokens.spaceXl),
                nextSteps,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: financialOverview),
              SizedBox(width: tokens.spaceXl),
              Expanded(flex: 2, child: nextSteps),
            ],
          );
        },
      ),
      SizedBox(height: tokens.spaceXl),
      _DesktopQuickActions(actions: _quickActions()),
      if (_showTip) ...[
        SizedBox(height: tokens.spaceXl),
        _Tip(
          onDismiss: () => setState(() => _tipDismissed = true),
          onAction: widget.onNewAccount,
        ),
      ],
      SizedBox(height: tokens.spaceXl),
      _AccountsOverview(
        accounts: widget.store.accounts,
        transactions: widget.store.transactions,
        hideValues: widget.hideValues,
        onOpenAccounts: widget.onOpenAccounts ?? widget.onNewAccount,
      ),
      SizedBox(height: tokens.spaceXl),
      LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
          final useColumns = constraints.maxWidth >= 960 && !largeText;
          if (!useColumns) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                expensesSection,
                SizedBox(height: tokens.spaceXl),
                incomesSection,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: expensesSection),
              SizedBox(width: tokens.spaceXl),
              Expanded(child: incomesSection),
            ],
          );
        },
      ),
    ];
  }

  bool get _showTip => widget.store.accounts.isEmpty && !_tipDismissed;

  List<QuickActionItem> _quickActions() => [
        QuickActionItem(
          icon: Icons.add_rounded,
          label: 'Nova despesa',
          tone: QuickActionTone.brand,
          onPressed: widget.onNewTransaction,
        ),
        QuickActionItem(
          icon: Icons.south_west_rounded,
          label: 'Nova receita',
          tone: QuickActionTone.positive,
          onPressed: widget.onNewIncome ?? widget.onNewTransaction,
        ),
        QuickActionItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Transferir',
          tone: QuickActionTone.brand,
          onPressed: widget.onTransfer ?? widget.onNewTransaction,
        ),
        QuickActionItem(
          icon: Icons.credit_card_outlined,
          label: 'Cartões',
          tone: QuickActionTone.brand,
          onPressed: widget.onOpenCards,
        ),
      ];

  String _money(int cents) =>
      widget.hideValues ? '••••••' : FinancialRules.formatBrl(cents);
}

class _MonthToolbar extends StatelessWidget {
  const _MonthToolbar({
    required this.month,
    required this.compact,
    required this.hideValues,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleValues,
    this.onNewTransaction,
  });

  final DateTime month;
  final bool compact;
  final bool hideValues;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToggleValues;
  final VoidCallback? onNewTransaction;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final label = '${sentenceCase(monthName(month.month))} de ${month.year}';
    if (!compact) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visão do período',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(height: tokens.spaceXs),
                Text(label, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _monthButton(
                  tooltip: 'Mês anterior',
                  onPressed: onPrevious,
                  icon: Icons.chevron_left_rounded,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
                  child: Text(
                    sentenceCase(monthName(month.month)),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                _monthButton(
                  tooltip: 'Próximo mês',
                  onPressed: onNext,
                  icon: Icons.chevron_right_rounded,
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          _visibilityButton(outlined: true),
          if (onNewTransaction != null) ...[
            SizedBox(width: tokens.spaceMd),
            FilledButton.icon(
              key: const Key('desktop-new-transaction'),
              onPressed: onNewTransaction,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova transação'),
            ),
          ],
        ],
      );
    }
    if (largeText) {
      return Wrap(
        spacing: tokens.spaceSm,
        runSpacing: tokens.spaceSm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          _monthButton(
            tooltip: 'Mês anterior',
            onPressed: onPrevious,
            icon: Icons.chevron_left_rounded,
            outlined: true,
          ),
          _monthButton(
            tooltip: 'Próximo mês',
            onPressed: onNext,
            icon: Icons.chevron_right_rounded,
            outlined: true,
          ),
          _visibilityButton(outlined: true),
        ],
      );
    }
    return Row(
      children: [
        _monthButton(
          tooltip: 'Mês anterior',
          onPressed: onPrevious,
          icon: Icons.chevron_left_rounded,
          outlined: true,
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Semantics(
            label: 'Mês selecionado: $label',
            child: Container(
              constraints: BoxConstraints(minHeight: tokens.minTapTarget),
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined),
                  SizedBox(width: tokens.spaceSm),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        _monthButton(
          tooltip: 'Próximo mês',
          onPressed: onNext,
          icon: Icons.chevron_right_rounded,
          outlined: true,
        ),
        SizedBox(width: tokens.spaceXs),
        _visibilityButton(),
      ],
    );
  }

  Widget _monthButton({
    required String tooltip,
    required VoidCallback onPressed,
    required IconData icon,
    bool outlined = false,
  }) =>
      Builder(builder: (context) {
        final tokens = OrganizaDesignTokens.of(context);
        return Container(
          decoration: outlined
              ? BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  shape: BoxShape.circle,
                )
              : null,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            constraints: BoxConstraints(
              minWidth: tokens.minTapTarget,
              minHeight: tokens.minTapTarget,
            ),
            icon: Icon(icon),
          ),
        );
      });

  Widget _visibilityButton({bool outlined = false}) =>
      Builder(builder: (context) {
        final tokens = OrganizaDesignTokens.of(context);
        return Container(
          decoration: outlined
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                )
              : null,
          child: IconButton(
            tooltip: hideValues ? 'Mostrar valores' : 'Ocultar valores',
            onPressed: onToggleValues,
            constraints: BoxConstraints(
              minWidth: tokens.minTapTarget,
              minHeight: tokens.minTapTarget,
            ),
            icon: Icon(
              hideValues
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        );
      });
}

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

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.available,
    required this.current,
    required this.hideValues,
    this.hint,
  });

  final String available;
  final String current;
  final bool hideValues;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final theme = Theme.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final semanticAvailable = hideValues ? 'valor oculto' : available;
    final semanticCurrent = hideValues ? 'valor oculto' : current;
    return Semantics(
      container: true,
      label:
          'Disponível no mês: $semanticAvailable. Saldo atual: $semanticCurrent${hint == null ? '' : '. $hint'}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (largeText) ...[
              _HeroWalletIcon(tokens: tokens, theme: theme),
              SizedBox(height: tokens.spaceMd),
              Text('Disponível no mês', style: theme.textTheme.titleMedium),
              SizedBox(height: tokens.spaceSm),
              _HeroValue(value: available),
            ] else
              Row(
                children: [
                  _HeroWalletIcon(tokens: tokens, theme: theme),
                  SizedBox(width: tokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disponível no mês',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: tokens.spaceXs),
                        _HeroValue(value: available),
                      ],
                    ),
                  ),
                ],
              ),
            SizedBox(height: tokens.spaceMd),
            Divider(
              height: tokens.hairlineThickness,
              thickness: tokens.hairlineThickness,
            ),
            SizedBox(height: tokens.spaceMd),
            if (hint != null)
              Text(hint!, style: theme.textTheme.bodyMedium)
            else if (largeText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo atual', style: theme.textTheme.bodySmall),
                  SizedBox(height: tokens.spaceXs),
                  Text(current, style: theme.textTheme.titleMedium),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child:
                        Text('Saldo atual', style: theme.textTheme.bodySmall),
                  ),
                  Text(current, style: theme.textTheme.titleMedium),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroWalletIcon extends StatelessWidget {
  const _HeroWalletIcon({required this.tokens, required this.theme});

  final OrganizaDesignTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
        width: tokens.quickActionDiameter,
        height: tokens.quickActionDiameter,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: .16),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.account_balance_wallet_outlined,
          color: theme.colorScheme.primary,
        ),
      );
}

class _HeroValue extends StatelessWidget {
  const _HeroValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Text(
        value,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

class _HeroSurface extends StatelessWidget {
  const _HeroSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.heroSurfaceStrong, tokens.heroSurface],
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .28),
          width: tokens.hairlineThickness,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: child,
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.onDismiss, required this.onAction});

  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Faça sua primeira conta',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: tokens.spaceXs),
              const Text(
                'Assim você acompanha seu saldo desde o primeiro lançamento.',
              ),
              Wrap(
                spacing: tokens.spaceSm,
                children: [
                  TextButton(
                    onPressed: onAction,
                    child: const Text('Criar conta'),
                  ),
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dispensar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({
    required this.onNewAccount,
    required this.onNewTransaction,
  });

  final VoidCallback onNewAccount;
  final VoidCallback onNewTransaction;

  @override
  Widget build(BuildContext context) => HairlineSection(
        title: 'Comece pelo básico',
        child: Wrap(
          spacing: OrganizaDesignTokens.of(context).spaceSm,
          runSpacing: OrganizaDesignTokens.of(context).spaceSm,
          children: [
            FilledButton.icon(
              onPressed: onNewAccount,
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Criar primeira conta'),
            ),
            OutlinedButton.icon(
              onPressed: onNewTransaction,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar primeiro lançamento'),
            ),
          ],
        ),
      );
}

class _OverdueNotice extends StatelessWidget {
  const _OverdueNotice({
    required this.count,
    required this.totalInCents,
    required this.hideValues,
    required this.onPressed,
  });

  final int count;
  final int totalInCents;
  final bool hideValues;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final label = count == 1 ? '1 conta atrasada' : '$count contas atrasadas';
    final value =
        hideValues ? '••••••' : FinancialRules.formatBrl(totalInCents);
    return Semantics(
      button: true,
      label: '$label, total $value. Ver lançamentos',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: Text(
                  '$label · $value',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EssentialsSection extends StatelessWidget {
  const _EssentialsSection({
    required this.invoice,
    required this.subscription,
    required this.budget,
    required this.cardStyle,
    required this.hideValues,
    required this.onOpenCards,
    required this.onOpenSubscriptions,
    required this.onOpenBudgets,
  });

  final _NextInvoice? invoice;
  final _NextSubscription? subscription;
  final _BudgetSummary? budget;
  final bool cardStyle;
  final bool hideValues;
  final VoidCallback onOpenCards;
  final VoidCallback onOpenSubscriptions;
  final VoidCallback onOpenBudgets;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final rows = Column(
      children: [
        _EssentialRow(
          icon: Icons.credit_card_outlined,
          label: 'Próxima fatura',
          description: invoice == null
              ? 'Adicione um cartão para acompanhar'
              : '${invoice!.card.name} · vence em ${shortDate(invoice!.dueDate)}',
          value: invoice == null
              ? null
              : _visibleMoney(invoice!.amountInCents, hideValues),
          cardStyle: cardStyle,
          onPressed: onOpenCards,
        ),
        _EssentialRow(
          icon: Icons.autorenew_rounded,
          label: 'Próxima assinatura',
          description: subscription == null
              ? 'Nenhuma assinatura ativa'
              : '${subscription!.subscription.name} · ${shortDate(subscription!.billingDate)}',
          value: subscription == null
              ? null
              : _visibleMoney(
                  subscription!.subscription.amountInCents,
                  hideValues,
                ),
          cardStyle: cardStyle,
          onPressed: onOpenSubscriptions,
        ),
        _EssentialRow(
          icon: Icons.donut_small_rounded,
          label: 'Orçamento do mês',
          description: budget == null
              ? 'Defina limites para saber quanto ainda pode gastar'
              : '${budget!.usedPercent}% do limite utilizado',
          value: budget == null
              ? null
              : 'Restam ${_visibleMoney(budget!.remainingInCents, hideValues)}',
          progress: budget?.progress,
          cardStyle: cardStyle,
          onPressed: onOpenBudgets,
        ),
      ],
    );
    if (!cardStyle) {
      return HairlineSection(title: 'Próximos passos', child: rows);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximos passos', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: tokens.spaceMd),
        rows,
      ],
    );
  }
}

class _EssentialRow extends StatelessWidget {
  const _EssentialRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.cardStyle,
    required this.onPressed,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String description;
  final String? value;
  final bool cardStyle;
  final VoidCallback onPressed;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: tokens.spaceXs),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        if (largeText && value != null) ...[
          SizedBox(height: tokens.spaceXs),
          Text(value!, style: Theme.of(context).textTheme.labelLarge),
        ],
        if (progress != null) ...[
          SizedBox(height: tokens.spaceSm),
          LinearProgressIndicator(
            value: progress,
            minHeight: tokens.hairlineThickness * 4,
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
        ],
      ],
    );
    final row = Semantics(
      button: true,
      label: '$label. $description${value == null ? '' : '. $value'}',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          cardStyle ? tokens.radiusMd : tokens.radiusSm,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.minTapTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: tokens.spaceSm),
                Expanded(child: details),
                if (!largeText && value != null) ...[
                  SizedBox(width: tokens.spaceSm),
                  Flexible(
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
                SizedBox(width: tokens.spaceXs),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
    if (!cardStyle) return row;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
          child: row,
        ),
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.title,
    required this.items,
    required this.accounts,
    required this.hideValues,
    required this.emptyText,
    required this.onSeeAll,
  });

  final String title;
  final List<TransactionRecord> items;
  final List<Account> accounts;
  final bool hideValues;
  final String emptyText;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => HairlineSection(
        title: title,
        trailing: items.isEmpty
            ? null
            : TextButton(onPressed: onSeeAll, child: const Text('Ver todas')),
        child: items.isEmpty
            ? _InlineEmpty(
                icon: Icons.receipt_long_outlined,
                text: emptyText,
              )
            : Column(
                children: [
                  for (final item in items.take(5))
                    _RecentTransactionRow(
                      item: item,
                      account: _findAccount(accounts, item.accountId),
                      hideValues: hideValues,
                    ),
                ],
              ),
      );
}

class _RecentTransactionRow extends StatelessWidget {
  const _RecentTransactionRow({
    required this.item,
    required this.account,
    required this.hideValues,
  });

  final TransactionRecord item;
  final Account? account;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final tokens = OrganizaDesignTokens.of(context);
    final income = item.type == TransactionType.income;
    final value = hideValues
        ? '••••••'
        : '${income ? '+' : '−'}${FinancialRules.formatBrl(item.amountInCents)}';
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return Semantics(
      label:
          '${income ? 'Entrada' : 'Despesa'}: ${item.description}, ${shortDate(item.occurredOn)}, $value',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InstitutionMark(
              institution: account?.institution ?? AccountInstitution.generic,
              customIconKey: account?.customIconKey,
              size: tokens.quickActionDiameter - tokens.spaceMd,
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description.isEmpty ? item.category : item.description,
                    maxLines: largeText ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    '${shortDate(item.occurredOn)} · ${account?.name ?? item.category}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (largeText) ...[
                    SizedBox(height: tokens.spaceXs),
                    _TransactionValue(value: value, income: income),
                  ],
                ],
              ),
            ),
            if (!largeText) ...[
              SizedBox(width: tokens.spaceSm),
              _TransactionValue(value: value, income: income),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransactionValue extends StatelessWidget {
  const _TransactionValue({required this.value, required this.income});

  final String value;
  final bool income;

  @override
  Widget build(BuildContext context) => Text(
        value,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: income
                  ? OrganizaDesignTokens.of(context).positive
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
      );
}

class _ReportLink extends StatelessWidget {
  const _ReportLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.query_stats_rounded),
          label: const Text('Ver relatório mensal completo'),
        ),
      );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(width: OrganizaDesignTokens.of(context).spaceSm),
          Expanded(child: Text(text)),
        ],
      );
}

class _NextInvoice {
  const _NextInvoice({
    required this.card,
    required this.dueDate,
    required this.amountInCents,
  });

  final CreditCard card;
  final DateTime dueDate;
  final int amountInCents;
}

class _NextSubscription {
  const _NextSubscription({
    required this.subscription,
    required this.billingDate,
  });

  final Subscription subscription;
  final DateTime billingDate;
}

class _BudgetSummary {
  const _BudgetSummary({
    required this.remainingInCents,
    required this.progress,
  });

  final int remainingInCents;
  final double progress;
  int get usedPercent => (progress * 100).round();
}

_NextInvoice? _nextInvoice(OrganizaStore store, DateTime reference) {
  _NextInvoice? result;
  for (final card in store.creditCards) {
    var dueDate = _safeDate(reference.year, reference.month, card.dueDay);
    if (dueDate.isBefore(_dateOnly(reference))) {
      dueDate = _safeDate(reference.year, reference.month + 1, card.dueDay);
    }
    final closingMonthOffset = card.dueDay > card.closingDay ? 0 : -1;
    final closingDate = _safeDate(
      dueDate.year,
      dueDate.month + closingMonthOffset,
      card.closingDay,
    );
    final candidate = _NextInvoice(
      card: card,
      dueDate: dueDate,
      amountInCents: CreditCardRules.currentInvoiceTotal(
        card,
        store.cardPurchases,
        closingDate,
      ),
    );
    if (result == null || candidate.dueDate.isBefore(result.dueDate)) {
      result = candidate;
    }
  }
  return result;
}

_NextSubscription? _nextSubscription(
  Iterable<Subscription> subscriptions,
  DateTime reference,
) {
  _NextSubscription? result;
  for (final subscription in subscriptions.where((item) => item.isActive)) {
    var billingDate =
        _safeDate(reference.year, reference.month, subscription.billingDay);
    if (billingDate.isBefore(_dateOnly(reference))) {
      billingDate = _safeDate(
        reference.year,
        reference.month + 1,
        subscription.billingDay,
      );
    }
    final candidate = _NextSubscription(
      subscription: subscription,
      billingDate: billingDate,
    );
    if (result == null || candidate.billingDate.isBefore(result.billingDate)) {
      result = candidate;
    }
  }
  return result;
}

_BudgetSummary? _budgetSummary(OrganizaStore store, DateTime month) {
  final budgets = store.budgets
      .where((item) => item.year == month.year && item.month == month.month)
      .toList();
  if (budgets.isEmpty) return null;
  final limit = budgets.fold(0, (total, item) => total + item.limitInCents);
  final spent = budgets.fold(
    0,
    (total, item) =>
        total + FinancialRules.budgetSpent(item, store.transactions),
  );
  final remaining = limit - spent;
  return _BudgetSummary(
    remainingInCents: remaining < 0 ? 0 : remaining,
    progress: limit <= 0 ? 0 : (spent / limit).clamp(0, 1).toDouble(),
  );
}

List<TransactionRecord> _monthTransactions(
  Iterable<TransactionRecord> source,
  DateTime month,
) =>
    source
        .where((item) =>
            item.occurredOn.year == month.year &&
            item.occurredOn.month == month.month)
        .toList();

List<TransactionRecord> _recentTransactions(
  Iterable<TransactionRecord> source,
  TransactionType type,
) {
  final result =
      source.where((item) => item.type == type && item.isSettled).toList()
        ..sort((a, b) {
          final byDate = b.occurredOn.compareTo(a.occurredOn);
          return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
        });
  return result.take(5).toList();
}

Account? _findAccount(Iterable<Account> accounts, String id) {
  for (final account in accounts) {
    if (account.id == id) return account;
  }
  return null;
}

String _visibleMoney(int cents, bool hideValues) =>
    hideValues ? '••••••' : FinancialRules.formatBrl(cents);

DateTime _referenceForMonth(DateTime month, DateTime today) =>
    month.year == today.year && month.month == today.month
        ? today
        : DateTime(month.year, month.month);

DateTime _safeDate(int year, int month, int day) {
  final normalized = DateTime(year, month);
  final lastDay = DateTime(normalized.year, normalized.month + 1, 0).day;
  return DateTime(normalized.year, normalized.month, day.clamp(1, lastDay));
}

DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);
DateTime _shiftMonth(DateTime value, int amount) =>
    DateTime(value.year, value.month + amount);
DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
