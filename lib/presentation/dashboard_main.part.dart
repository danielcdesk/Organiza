part of 'dashboard_page.dart';

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
    this.onOpenOrganization,
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
  final VoidCallback? onOpenOrganization;
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
          icon: Icons.more_horiz_rounded,
          label: 'Mais ações',
          tone: QuickActionTone.neutral,
          onPressed: _showMoreActions,
        ),
      ];

  Future<void> _showMoreActions() async {
    Widget actionTile(BuildContext menuContext, IconData icon, String label,
            VoidCallback action) =>
        ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: () {
            Navigator.of(menuContext).pop();
            action();
          },
        );

    final actions = <(IconData, String, VoidCallback)>[
      (Icons.add_home_work_outlined, 'Adicionar conta', widget.onNewAccount),
      (Icons.credit_card_outlined, 'Cartões', widget.onOpenCards),
      if (widget.onOpenOrganization != null)
        (
          Icons.account_tree_outlined,
          'Organização',
          widget.onOpenOrganization!
        ),
    ];
    if (MediaQuery.sizeOf(context).width < 600) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (menuContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (icon, label, action) in actions)
                actionTile(menuContext, icon, label, action),
            ],
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (menuContext) => SimpleDialog(
          title: const Text('Mais ações'),
          children: [
            for (final (icon, label, action) in actions)
              actionTile(menuContext, icon, label, action),
          ],
        ),
      );
    }
  }

  String _money(int cents) =>
      widget.hideValues ? '••••••' : FinancialRules.formatBrl(cents);
}
