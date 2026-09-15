import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../application/organiza_store.dart';
import '../domain/models.dart';
import 'basic_pages.dart';
import 'cards_page.dart';
import 'budgets_page.dart';
import 'subscriptions_page.dart';
import 'dashboard_page.dart';
import 'dialogs.dart';
import 'investments_page.dart';
import 'goals_page.dart';
import 'organiza_theme.dart';
import 'reports_page.dart';
import 'shared_widgets.dart';
import 'shopping_page.dart';
import '../services/report_export_service.dart';

class OrganizaApp extends StatefulWidget {
  const OrganizaApp({super.key, required this.store});

  final OrganizaStore store;

  @override
  State<OrganizaApp> createState() => _OrganizaAppState();
}

class _OrganizaAppState extends State<OrganizaApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Organiza',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: OrganizaTheme.light(),
        darkTheme: OrganizaTheme.dark(),
        home: OrganizaShell(
          store: widget.store,
          onThemeChanged: (mode) => setState(() => _themeMode = mode),
        ),
      );
}

class OrganizaShell extends StatefulWidget {
  const OrganizaShell({
    super.key,
    required this.store,
    required this.onThemeChanged,
  });

  final OrganizaStore store;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<OrganizaShell> createState() => _OrganizaShellState();
}

class _OrganizaShellState extends State<OrganizaShell> {
  var _page = 0;
  var _collapsed = false;
  var _hideValues = false;
  var _isFullscreen = false;

  static const _pages = <_PageDefinition>[
    _PageDefinition('Visão geral', Icons.space_dashboard_outlined),
    _PageDefinition('Finanças', Icons.swap_vert_circle_outlined),
    _PageDefinition('Contas', Icons.account_balance_wallet_outlined),
    _PageDefinition('Cartões', Icons.credit_card_outlined),
    _PageDefinition('Orçamentos', Icons.donut_large_outlined),
    _PageDefinition('Investimentos', Icons.show_chart_outlined),
    _PageDefinition('Planejamento', Icons.checklist_rounded),
    _PageDefinition('Metas', Icons.flag_outlined),
    _PageDefinition('Relatórios', Icons.bar_chart_rounded),
    _PageDefinition('Configurações', Icons.tune_rounded),
    _PageDefinition('Assinaturas', Icons.autorenew_rounded),
    _PageDefinition('Lista de desejos', Icons.shopping_bag_outlined),
  ];

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyK, control: true):
              _SearchIntent(),
          SingleActivator(LogicalKeyboardKey.keyN, control: true):
              _TransactionIntent(),
          SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true):
              _TaskIntent(),
          SingleActivator(LogicalKeyboardKey.comma, control: true):
              _SettingsIntent(),
          SingleActivator(LogicalKeyboardKey.f11): _FullscreenIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _SearchIntent:
                CallbackAction<_SearchIntent>(onInvoke: (_) => _openSearch()),
            _TransactionIntent: CallbackAction<_TransactionIntent>(
                onInvoke: (_) => _openTransactionDialog()),
            _TaskIntent:
                CallbackAction<_TaskIntent>(onInvoke: (_) => _openTaskDialog()),
            _SettingsIntent: CallbackAction<_SettingsIntent>(
                onInvoke: (_) => setState(() => _page = 9)),
            _FullscreenIntent: CallbackAction<_FullscreenIntent>(
                onInvoke: (_) => _toggleFullscreen()),
          },
          child: Focus(
            autofocus: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1040;
                return Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _Sidebar(
                            collapsed: _collapsed || compact,
                            selected: _page,
                            pages: _pages,
                            onSelect: (index) => setState(() => _page = index),
                            onCollapse: compact
                                ? null
                                : () =>
                                    setState(() => _collapsed = !_collapsed),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              children: [
                                _TopBar(
                                  title: _pages[_page].label,
                                  hideValues: _hideValues,
                                  onSearch: _openSearch,
                                  onToggleValues: () => setState(
                                      () => _hideValues = !_hideValues),
                                  onThemeChanged: widget.onThemeChanged,
                                  isFullscreen: _isFullscreen,
                                  onToggleFullscreen: _toggleFullscreen,
                                ),
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(.018, 0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                    child: KeyedSubtree(
                                      key: ValueKey(_page),
                                      child: _buildPage(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  Widget _buildPage() => switch (_page) {
        0 => DashboardPage(
            store: widget.store,
            hideValues: _hideValues,
            onNewTransaction: _openTransactionDialog,
            onNewTask: _openTaskDialog,
            onDeleteTask: _deleteTask,
            onOpenCards: () => setState(() => _page = 3),
            onOpenBudgets: () => setState(() => _page = 4),
            onOpenSubscriptions: () => setState(() => _page = 10),
          ),
        1 => TransactionsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openTransactionDialog,
            onDelete: _deleteTransaction,
            onSettledChanged: widget.store.setTransactionSettled,
          ),
        2 => AccountsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openAccountDialog,
            onDelete: _deleteAccount,
          ),
        3 => CardsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAddCard: _openCardDialog,
            onAddPurchase: _openCardPurchaseDialog,
          ),
        4 => BudgetsPage(
            store: widget.store,
            onAdd: _openBudgetDialog,
            onDelete: _deleteBudget),
        5 => InvestmentsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openInvestmentDialog,
            onDelete: _deleteInvestment,
          ),
        6 => PlanningPage(
            store: widget.store,
            onAdd: _openTaskDialog,
            onDeleteTask: _deleteTask,
          ),
        7 => GoalsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openFinancialGoalDialog,
            onContribute: _openGoalContributionDialog,
            onDelete: _deleteFinancialGoal,
          ),
        8 => ReportsPage(
            store: widget.store,
            hideValues: _hideValues,
            onExport: _exportReport,
          ),
        9 => SettingsPage(onThemeChanged: widget.onThemeChanged),
        10 => SubscriptionsPage(
            store: widget.store,
            onAdd: _openSubscriptionDialog,
            onDelete: _deleteSubscription),
        11 => ShoppingPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openShoppingDialog,
            onDelete: _deleteShoppingItem,
          ),
        _ => ComingSoonPage(title: _pages[_page].label),
      };

  Future<void> _toggleFullscreen() async {
    final next = !_isFullscreen;
    try {
      await windowManager.setFullScreen(next);
      if (mounted) setState(() => _isFullscreen = next);
    } catch (_) {
      _showError('Tela cheia está disponível apenas no app para Windows.');
    }
  }

  Future<void> _openAccountDialog() async {
    final value = await showDialog<AccountInput>(
      context: context,
      builder: (_) => const AccountDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addAccount(
        value.name,
        value.openingCents,
        institution: value.institution,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a conta.');
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    Account? account;
    for (final item in widget.store.accounts) {
      if (item.id == accountId) {
        account = item;
        break;
      }
    }
    if (account == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir ${account!.name}?'),
        content: const Text(
            'A conta só pode ser excluída quando não possui transações vinculadas.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      widget.store.deleteAccount(accountId);
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível excluir a conta.');
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir lançamento?',
      message: 'O saldo e os relatórios serão recalculados imediatamente.',
    );
    if (confirmed) widget.store.deleteTransaction(transactionId);
  }

  Future<void> _deleteBudget(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir orçamento?',
      message: 'O limite mensal desta categoria será removido.',
    );
    if (confirmed) widget.store.deleteBudget(id);
  }

  Future<void> _deleteSubscription(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir assinatura?',
      message: 'A cobrança recorrente deixará de aparecer no calendário.',
    );
    if (confirmed) widget.store.deleteSubscription(id);
  }

  Future<bool> _confirmDelete(
      {required String title, required String message}) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Excluir')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openTransactionDialog() async {
    if (widget.store.accounts.isEmpty) {
      _showError('Crie uma conta antes de registrar uma transação.');
      return;
    }
    final value = await showDialog<TransactionInput>(
      context: context,
      builder: (_) => TransactionDialog(
        accounts: widget.store.accounts,
        categories: widget.store.financeCategories,
        subcategories: widget.store.financeSubcategories,
        onCreateCategory: widget.store.addFinanceCategory,
        onCreateSubcategory: widget.store.addFinanceSubcategory,
      ),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addTransaction(
        accountId: value.accountId,
        destinationAccountId: value.destinationAccountId,
        type: value.type,
        amountInCents: value.amountInCents,
        description: value.description,
        category: value.category,
        subcategory: value.subcategory,
        occurredOn: value.occurredOn,
        scheduleType: value.scheduleType,
        repeatCount: value.repeatCount,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a transação.');
    }
  }

  Future<void> _openTaskDialog() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => const TaskDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addTask(value);
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a tarefa.');
    }
  }

  Future<void> _deleteTask(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir tarefa?',
      message: 'A tarefa será removida da sua lista local.',
    );
    if (confirmed) widget.store.deleteTask(id);
  }

  Future<void> _openShoppingDialog() async {
    final value = await showDialog<ShoppingInput>(
      context: context,
      builder: (_) => const ShoppingDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addShoppingItem(
        name: value.name,
        quantity: value.quantity,
        estimatedUnitPriceInCents: value.estimatedUnitPriceInCents,
        priority: value.priority,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o item.');
    }
  }

  Future<void> _deleteShoppingItem(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir item?',
      message: 'O item será removido da lista de desejos/compras.',
    );
    if (confirmed) widget.store.deleteShoppingItem(id);
  }

  Future<void> _openFinancialGoalDialog() async {
    final value = await showDialog<FinancialGoalInput>(
      context: context,
      builder: (_) => const FinancialGoalDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addFinancialGoal(
        name: value.name,
        targetInCents: value.targetInCents,
        initialSavedInCents: value.initialSavedInCents,
        deadline: value.deadline,
        iconKey: value.iconKey,
      );
    } on ArgumentError catch (error) {
      _showError(error.message?.toString() ?? 'Não foi possível criar a meta.');
    }
  }

  Future<void> _openGoalContributionDialog(FinancialGoal goal) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => GoalContributionDialog(goalName: goal.name),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.contributeToFinancialGoal(goal.id, value);
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o aporte.');
    }
  }

  Future<void> _deleteFinancialGoal(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir meta?',
      message: 'O progresso registrado nesta meta será removido.',
    );
    if (confirmed) widget.store.deleteFinancialGoal(id);
  }

  Future<void> _deleteInvestment(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir investimento?',
      message: 'A posição manual será removida da carteira consolidada.',
    );
    if (confirmed) widget.store.deleteInvestment(id);
  }

  Future<void> _openCardDialog() async {
    final value = await showDialog<CardInput>(
      context: context,
      builder: (_) => const CardDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addCreditCard(
        name: value.name,
        brand: value.brand,
        lastFour: value.lastFour,
        limitInCents: value.limitInCents,
        closingDay: value.closingDay,
        dueDay: value.dueDay,
        colorValue: value.colorValue,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o cartão.');
    }
  }

  Future<void> _openCardPurchaseDialog([String? initialCardId]) async {
    if (widget.store.creditCards.isEmpty) {
      _showError('Cadastre um cartão antes de registrar uma compra.');
      return;
    }
    final value = await showDialog<CardPurchaseInput>(
      context: context,
      builder: (_) => CardPurchaseDialog(
        cards: widget.store.creditCards,
        initialCardId: initialCardId,
      ),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addCardPurchase(
        cardId: value.cardId,
        description: value.description,
        amountInCents: value.amountInCents,
        installments: value.installments,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a compra.');
    }
  }

  Future<void> _openInvestmentDialog() async {
    final value = await showDialog<InvestmentInput>(
      context: context,
      builder: (_) => const InvestmentDialog(),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addInvestment(
        name: value.name,
        type: value.type,
        investedAmountInCents: value.investedAmountInCents,
        currentValueInCents: value.currentValueInCents,
        fixedIncomeType: value.fixedIncomeType,
        institutionName: value.institutionName,
        maturityDate: value.maturityDate,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o ativo.');
    }
  }

  Future<void> _openBudgetDialog() async {
    final categories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.name)
        .toList();
    final value = await showDialog<BudgetInput>(
      context: context,
      builder: (_) => BudgetDialog(categories: categories),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addBudget(
        category: value.category,
        limitInCents: value.limitInCents,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o orçamento.');
    }
  }

  Future<void> _openSubscriptionDialog() async {
    final categories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.name)
        .toList();
    final value = await showDialog<SubscriptionInput>(
      context: context,
      builder: (_) => SubscriptionDialog(categories: categories),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addSubscription(
        name: value.name,
        amountInCents: value.amountInCents,
        billingDay: value.billingDay,
        category: value.category,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a assinatura.');
    }
  }

  Future<void> _exportReport(DateTime month, bool includePending) async {
    try {
      final transactions = widget.store.transactions.where((item) =>
          item.occurredOn.year == month.year &&
          item.occurredOn.month == month.month &&
          (includePending || item.isSettled));
      final file = await const ReportExportService().exportTransactions(
        transactions,
        period: month,
      );
      if (!mounted) return;
      _showError('Relatório salvo em ${file.path}');
    } on FileSystemException {
      if (mounted) _showError('Não foi possível exportar o relatório.');
    }
  }

  Future<void> _openSearch() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SearchDialog(
        store: widget.store,
        onNavigate: (page) {
          Navigator.pop(context);
          setState(() => _page = page);
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.selected,
    required this.pages,
    required this.onSelect,
    required this.onCollapse,
  });

  final bool collapsed;
  final int selected;
  final List<_PageDefinition> pages;
  final ValueChanged<int> onSelect;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final sidebarTheme = parentTheme.copyWith(
      dividerColor: const Color(0xFF343438),
      colorScheme: const ColorScheme.dark(
        primary: OrganizaTheme.orange,
        onPrimary: Colors.white,
        surface: Color(0xFF1D1D20),
        onSurface: Color(0xFFF6F6F7),
        onSurfaceVariant: Color(0xFFB7B7BC),
      ),
    );
    return Theme(
      data: sidebarTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: collapsed ? 72 : 224,
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/branding/organiza-app-icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 10),
                      const Text(
                        'ORGANIZA',
                        style: TextStyle(
                          color: Color(0xFFF6F6F7),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _section(context, [0]),
              _label('FINANÇAS'),
              _section(context, [1, 2, 3, 4, 5, 10]),
              _label('ORGANIZAÇÃO'),
              _section(context, [6, 7, 11]),
              _label('ANÁLISE'),
              _section(context, [8]),
              const Spacer(),
              if (!collapsed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                  child: Material(
                    color: const Color(0xFF2B2B2E),
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      onTap: () => onSelect(9),
                      borderRadius: BorderRadius.circular(13),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: Color(0xFF48484D),
                              child: Icon(Icons.person_outline_rounded,
                                  size: 16, color: Color(0xFFF6F6F7)),
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Perfil local',
                                      style: TextStyle(
                                          color: Color(0xFFF6F6F7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(height: 2),
                                  Text('Somente neste dispositivo',
                                      style: TextStyle(
                                          color: Color(0xFFB7B7BC),
                                          fontSize: 10.5)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: Color(0xFFB7B7BC), size: 17),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              _section(context, [9]),
              if (onCollapse != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: IconButton(
                    onPressed: onCollapse,
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFFE4E4E7),
                    ),
                    tooltip: collapsed
                        ? 'Expandir barra lateral'
                        : 'Recolher barra lateral',
                    icon: Icon(collapsed
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_left),
                  ),
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => collapsed
      ? const SizedBox(height: 18)
      : Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF8F8F96),
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );

  Widget _section(BuildContext context, List<int> indices) => Column(
        children: indices.map((index) {
          final page = pages[index];
          final active = selected == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
            child: Tooltip(
              message: collapsed ? page.label : '',
              child: Material(
                color: active ? const Color(0xFFEEEEF0) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: collapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        if (!collapsed) ...[
                          Container(
                            width: 3,
                            height: 18,
                            decoration: BoxDecoration(
                              color: active
                                  ? OrganizaTheme.orange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(
                          page.icon,
                          size: 19,
                          color: active
                              ? OrganizaTheme.orange
                              : const Color(0xFFB7B7BC),
                        ),
                        if (!collapsed) ...[
                          const SizedBox(width: 12),
                          Text(
                            page.label,
                            style: TextStyle(
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? const Color(0xFF202023)
                                  : const Color(0xFFE4E4E7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.hideValues,
    required this.onSearch,
    required this.onToggleValues,
    required this.onThemeChanged,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  final String title;
  final bool hideValues;
  final VoidCallback onSearch;
  final VoidCallback onToggleValues;
  final ValueChanged<ThemeMode> onThemeChanged;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) => Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Material(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: .38),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: onSearch,
                  borderRadius: BorderRadius.circular(13),
                  child: const SizedBox(
                    height: 42,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 13),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18),
                          SizedBox(width: 9),
                          Expanded(child: Text('Buscar no Organiza')),
                          _KeyHint('Ctrl K'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleValues,
              tooltip: hideValues ? 'Mostrar valores' : 'Ocultar valores',
              icon: Icon(hideValues
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
            ),
            IconButton(
              onPressed: onToggleFullscreen,
              tooltip: isFullscreen ? 'Sair da tela cheia' : 'Tela cheia',
              icon: Icon(isFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded),
            ),
            PopupMenuButton<ThemeMode>(
              tooltip: 'Tema',
              icon: const Icon(Icons.brightness_6_outlined),
              onSelected: onThemeChanged,
              itemBuilder: (_) => const [
                PopupMenuItem(value: ThemeMode.system, child: Text('Sistema')),
                PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
                PopupMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
              ],
            ),
          ],
        ),
      );
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.store, required this.onNavigate});

  final OrganizaStore store;
  final ValueChanged<int> onNavigate;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _results();
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      title: TextField(
        autofocus: true,
        onChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Transações, contas, cartões, ativos ou tarefas',
          suffixIcon:
              Padding(padding: EdgeInsets.all(11), child: _KeyHint('Esc')),
        ),
      ),
      content: SizedBox(
        width: 560,
        height: 340,
        child: _query.isEmpty
            ? const EmptyState(
                icon: Icons.manage_search_rounded,
                title: 'Busca local',
                description:
                    'Digite para encontrar seus dados sem sair do computador.',
              )
            : results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Nada encontrado',
                    description: 'Tente outro termo de busca.',
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return ListTile(
                        leading: IconTile(icon: result.icon),
                        title: Text(result.title),
                        subtitle: Text(result.subtitle),
                        trailing:
                            const Icon(Icons.arrow_forward_rounded, size: 17),
                        onTap: () => widget.onNavigate(result.page),
                      );
                    },
                  ),
      ),
    );
  }

  List<_SearchResult> _results() {
    if (_query.isEmpty) return [];
    final results = <_SearchResult>[];
    for (final account in widget.store.accounts) {
      if (account.name.toLowerCase().contains(_query)) {
        results.add(_SearchResult(Icons.account_balance_outlined, account.name,
            'Conta · ${institutionName(account.institution)}', 2));
      }
    }
    for (final transaction in widget.store.transactions) {
      if (transaction.description.toLowerCase().contains(_query)) {
        results.add(
          _SearchResult(Icons.receipt_long_outlined, transaction.description,
              'Movimentação', 1),
        );
      }
    }
    for (final card in widget.store.creditCards) {
      if (card.name.toLowerCase().contains(_query) ||
          card.lastFour.contains(_query)) {
        results.add(
          _SearchResult(Icons.credit_card_outlined, card.name,
              'Cartão •••• ${card.lastFour}', 3),
        );
      }
    }
    for (final task in widget.store.tasks) {
      if (task.title.toLowerCase().contains(_query)) {
        results.add(
            _SearchResult(Icons.task_alt_outlined, task.title, 'Tarefa', 6));
      }
    }
    for (final investment in widget.store.investments) {
      if (investment.name.toLowerCase().contains(_query)) {
        results.add(_SearchResult(investmentTypeIcon(investment.type),
            investment.name, investmentTypeName(investment.type), 5));
      }
    }
    for (final budget in widget.store.budgets) {
      if (budget.category.toLowerCase().contains(_query)) {
        results.add(_SearchResult(Icons.track_changes_rounded, budget.category,
            'Orçamento mensal', 4));
      }
    }
    for (final goal in widget.store.financialGoals) {
      if (goal.name.toLowerCase().contains(_query)) {
        results.add(_SearchResult(
            Icons.flag_outlined, goal.name, 'Meta financeira', 7));
      }
    }
    return results.take(20).toList();
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: .45),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _SearchResult {
  const _SearchResult(this.icon, this.title, this.subtitle, this.page);
  final IconData icon;
  final String title;
  final String subtitle;
  final int page;
}

class _PageDefinition {
  const _PageDefinition(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _TransactionIntent extends Intent {
  const _TransactionIntent();
}

class _TaskIntent extends Intent {
  const _TaskIntent();
}

class _SettingsIntent extends Intent {
  const _SettingsIntent();
}

class _FullscreenIntent extends Intent {
  const _FullscreenIntent();
}
