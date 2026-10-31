import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import '../application/organiza_store.dart';
import '../domain/models.dart';
import '../domain/card_invoice_rules.dart';
import '../domain/financial_rules.dart';
import '../services/local_image_service.dart';
import 'basic_pages.dart';
import 'cards_page.dart';
import 'subscriptions_page.dart';
import 'dashboard_page.dart';
import 'dialogs.dart';
import 'investments_page.dart';
import 'goals_page.dart';
import 'organiza_theme.dart';
import 'organiza_icons.dart';
import 'reports_page.dart';
import 'shared_widgets.dart';
import 'shopping_page.dart';
import 'profile_setup_page.dart';
import 'welcome_page.dart';
import 'debug_component_catalog_page.dart';
import '../services/report_export_service.dart';

class OrganizaApp extends StatefulWidget {
  const OrganizaApp({super.key, required this.store});

  final OrganizaStore store;

  @override
  State<OrganizaApp> createState() => _OrganizaAppState();
}

class _OrganizaAppState extends State<OrganizaApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  late String _accentPreference;

  @override
  void initState() {
    super.initState();
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == widget.store.themePreference,
      orElse: () => ThemeMode.dark,
    );
    _accentPreference = widget.store.accentPreference;
  }

  void _changeTheme(ThemeMode mode) {
    widget.store.saveThemePreference(mode.name);
    setState(() => _themeMode = mode);
  }

  void _changeAccent(String value) {
    widget.store.saveAccentPreference(value);
    setState(() => _accentPreference = value);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Organiza',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        themeMode: _themeMode,
        theme: OrganizaTheme.light(_accentPreference),
        darkTheme: OrganizaTheme.dark(_accentPreference),
        routes: {
          if (kDebugMode)
            '/debug/components': (_) => const DebugComponentCatalogPage(),
        },
        home: OrganizaShell(
          store: widget.store,
          onThemeChanged: _changeTheme,
          onAccentChanged: _changeAccent,
        ),
      );
}

class OrganizaShell extends StatefulWidget {
  const OrganizaShell({
    super.key,
    required this.store,
    required this.onThemeChanged,
    required this.onAccentChanged,
  });

  final OrganizaStore store;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onAccentChanged;

  @override
  State<OrganizaShell> createState() => _OrganizaShellState();
}

class _OrganizaShellState extends State<OrganizaShell>
    with WindowListener, WidgetsBindingObserver {
  var _page = 0;
  var _collapsed = false;
  var _hideValues = false;
  var _isFullscreen = false;
  var _welcomeStarted = false;

  static const _pages = <_PageDefinition>[
    _PageDefinition('Visão geral', OrganizaIconName.dashboard),
    _PageDefinition('Finanças', OrganizaIconName.transactions),
    _PageDefinition('Contas', OrganizaIconName.wallet),
    _PageDefinition('Cartões', OrganizaIconName.creditCard),
    _PageDefinition('Orçamento', OrganizaIconName.budget),
    _PageDefinition('Investimentos', OrganizaIconName.investments),
    _PageDefinition('Organização', OrganizaIconName.organization),
    _PageDefinition('Metas', OrganizaIconName.goals),
    _PageDefinition('Relatórios', OrganizaIconName.reports),
    _PageDefinition('Configurações', OrganizaIconName.settings),
    _PageDefinition('Assinaturas', OrganizaIconName.subscriptions),
    _PageDefinition('Lista de desejos', OrganizaIconName.shopping),
  ];

  @override
  void initState() {
    super.initState();
    _hideValues = widget.store.hideValuesPreference;
    widget.store.addListener(_refresh);
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows) windowManager.addListener(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isAndroid && state == AppLifecycleState.paused) {
      unawaited(widget.store.runAutomaticBackup(closing: true));
    }
  }

  @override
  void onWindowClose() {
    unawaited(_closeWindow());
  }

  Future<void> _closeWindow() async {
    if (widget.store.automaticBackupEnabled && widget.store.backupOnClose) {
      await widget.store.runAutomaticBackup(closing: true);
      if (widget.store.backupError?.isNotEmpty == true && mounted) {
        final closeAnyway = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Backup não concluído'),
            content: Text(widget.store.backupError!),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Continuar no app')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Fechar mesmo assim')),
            ],
          ),
        );
        if (closeAnyway != true) return;
      }
    }
    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  void _toggleValues() {
    setState(() => _hideValues = !_hideValues);
    widget.store.saveHideValuesPreference(_hideValues);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows) windowManager.removeListener(this);
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _completeFirstProfile(
      String name, int incomeInCents, String? photoPath) {
    widget.store.saveProfile(
      name: name,
      incomeInCents: incomeInCents,
      photoPath: photoPath,
    );
    if (mounted) setState(() => _page = 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store.profileName.isEmpty) {
      if (!_welcomeStarted) {
        return WelcomePage(
          onStart: () => setState(() => _welcomeStarted = true),
          onRestore: _restoreEncryptedBackup,
          onPrivacy: _showPrivacyPolicy,
        );
      }
      return ProfileSetupPage(onComplete: _completeFirstProfile);
    }
    return Shortcuts(
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
              if (constraints.maxWidth < 600) return _buildMobileShell();
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
                          profileName: widget.store.profileName,
                          profilePhotoPath: widget.store.profilePhotoPath,
                          onSelect: (index) => setState(() => _page = index),
                          onCollapse: compact
                              ? null
                              : () => setState(() => _collapsed = !_collapsed),
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
                                onToggleValues: _toggleValues,
                                onThemeChanged: widget.onThemeChanged,
                                isFullscreen: _isFullscreen,
                                onToggleFullscreen: _toggleFullscreen,
                              ),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 280),
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
  }

  Widget _buildMobileShell() {
    final mobileTheme = OrganizaTheme.mobile(Theme.of(context));
    return Theme(
      data: mobileTheme,
      child: Builder(builder: (context) {
        final primaryPages = widget.store.mobileQuickPages;
        return Scaffold(
          appBar: AppBar(
            leading: Builder(
                builder: (context) => IconButton(
                    tooltip: 'Abrir navegação',
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(context).openDrawer())),
            title: Text(_pages[_page].label),
            actions: [
              IconButton(
                tooltip: 'Buscar',
                onPressed: _openSearch,
                icon: const Icon(Icons.search_rounded),
              ),
              if (_page != 0)
                IconButton(
                  tooltip: _hideValues ? 'Mostrar valores' : 'Ocultar valores',
                  onPressed: _toggleValues,
                  icon: Icon(_hideValues
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: LocalImageService.exists(
                              widget.store.profilePhotoPath)
                          ? FileImage(LocalImageService.fileFor(
                              widget.store.profilePhotoPath!))
                          : null,
                      child: !LocalImageService.exists(
                              widget.store.profilePhotoPath)
                          ? const Icon(Icons.person_outline_rounded)
                          : null,
                    ),
                    title: Text(
                      widget.store.profileName.isEmpty
                          ? 'Organiza'
                          : widget.store.profileName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(widget.store.profileName.isEmpty
                        ? 'Seu espaço financeiro · Perfil local'
                        : 'Perfil local · somente neste dispositivo'),
                    onTap: () {
                      Navigator.pop(context);
                      _openProfileDialog();
                    },
                  ),
                  const Divider(),
                  Expanded(
                      child: ListView(children: [
                    _mobileDrawerSection('INÍCIO', [0]),
                    _mobileDrawerSection('FINANÇAS', [1, 2, 3, 5, 10]),
                    _mobileDrawerSection('ORGANIZAÇÃO', [6, 7, 11]),
                    _mobileDrawerSection('ANÁLISE', [8]),
                    _mobileDrawerSection('PREFERÊNCIAS', [9]),
                  ])),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .018),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(_page), child: _buildPage()),
            ),
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: primaryPages.contains(_page)
                ? (primaryPages.indexOf(_page) < 2
                    ? primaryPages.indexOf(_page)
                    : primaryPages.indexOf(_page) + 1)
                : 0,
            items: [
              for (var slot = 0; slot < 5; slot++)
                AppBottomNavItem(
                  icon: slot == 2
                      ? Icons.add_rounded
                      : _mobileMaterialIcon(
                          primaryPages[slot < 2 ? slot : slot - 1]),
                  label: slot == 2
                      ? 'Nova'
                      : _mobileNavLabel(
                          primaryPages[slot < 2 ? slot : slot - 1]),
                  semanticLabel: slot == 2 ? 'Nova transação' : null,
                  primaryAction: slot == 2,
                  onPressed: () {
                    if (slot == 2) {
                      _openTransactionDialog();
                      return;
                    }
                    setState(
                        () => _page = primaryPages[slot < 2 ? slot : slot - 1]);
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  String _mobileNavLabel(int page) => switch (page) {
        0 => 'Início',
        5 => 'Investir',
        6 => 'Organizar',
        11 => 'Desejos',
        _ => _pages[page].label,
      };

  IconData _mobileMaterialIcon(int page) => switch (page) {
        0 => Icons.home_outlined,
        1 => Icons.swap_horiz_rounded,
        5 => Icons.insights_outlined,
        6 => Icons.checklist_rounded,
        8 => Icons.bar_chart_rounded,
        11 => Icons.shopping_bag_outlined,
        _ => Icons.more_horiz_rounded,
      };

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Política de privacidade'),
        content: const SingleChildScrollView(
          child: Text(
            'O Organiza guarda seus dados neste aparelho. Não precisamos de uma conta online para você usar o app.\n\n'
            'Você decide quando criar um backup e onde salvá-lo. Ao restaurar um backup, uma cópia do estado anterior é criada para segurança.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _mobileDrawerSection(String title, List<int> indices) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1))),
        for (final index in indices)
          ListTile(
              leading: OrganizaIcon(_pages[index].icon, size: 22),
              title: Text(_pages[index].label),
              selected: index == _page,
              onTap: () {
                Navigator.pop(context);
                setState(() => _page = index);
              }),
      ]);

  Widget _buildPage() => switch (_page) {
        0 => DashboardPage(
            store: widget.store,
            hideValues: _hideValues,
            onNewTransaction: _openTransactionDialog,
            onOpenCards: () => setState(() => _page = 3),
            onOpenTransactions: () => setState(() => _page = 1),
            onOpenGoals: () => setState(() => _page = 7),
            onOpenReports: () => setState(() => _page = 8),
            onOpenBudgets: () => setState(() => _page = 6),
            onOpenSubscriptions: () => setState(() => _page = 10),
            onOpenAccounts: () => setState(() => _page = 2),
            onNewAccount: _openAccountDialog,
            onToggleValues: _toggleValues,
            onNewIncome: () =>
                _openTransactionDialog(initialType: TransactionType.income),
            onTransfer: () =>
                _openTransactionDialog(initialType: TransactionType.transfer),
          ),
        1 => TransactionsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openTransactionDialog,
            onDelete: _deleteTransaction,
            onSettledChanged: widget.store.setTransactionSettled,
            onEdit: _editTransaction,
            onManageAttachments: _manageAttachments,
          ),
        2 => AccountsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openAccountDialog,
            onDelete: _deleteAccount,
            onEditBalance: _editAccountBalance,
            onEdit: _editAccount,
          ),
        3 => CardsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAddCard: _openCardDialog,
            onAddPurchase: _openCardPurchaseDialog,
            onManageInstallments: _manageCardPurchaseInstallments,
            onPayInvoice: _payCardInvoice,
            onReverseInvoicePayment: _reverseCardInvoicePayment,
          ),
        4 => PlanningPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openTaskDialog,
            onDeleteTask: _deleteTask,
            onAddBudget: _openBudgetDialog,
            onDeleteBudget: _deleteBudget,
            onCancelSalary: _cancelSalarySchedule),
        5 => InvestmentsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openInvestmentDialog,
            onEdit: _editInvestment,
            onDelete: _deleteInvestment,
          ),
        6 => PlanningPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openTaskDialog,
            onDeleteTask: _deleteTask,
            onAddBudget: _openBudgetDialog,
            onDeleteBudget: _deleteBudget,
            onCancelSalary: _cancelSalarySchedule,
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
        9 => SettingsPage(
            hideValues: _hideValues,
            onThemeChanged: widget.onThemeChanged,
            onAccentChanged: widget.onAccentChanged,
            accentPreference: widget.store.accentPreference,
            themePreference: widget.store.themePreference,
            quickPages: widget.store.mobileQuickPages,
            onQuickPagesChanged: widget.store.updateMobileQuickPages,
            profileName: widget.store.profileName,
            profileIncomeInCents: widget.store.profileIncomeInCents,
            profilePhotoPath: widget.store.profilePhotoPath,
            onEditProfile: _openProfileDialog,
            onExportBackup: _exportEncryptedBackup,
            onRestoreBackup: _restoreEncryptedBackup,
            financeCategories: widget.store.financeCategories,
            onRenameFinanceCategory: widget.store.renameFinanceCategory,
            onArchiveFinanceCategory: widget.store.archiveFinanceCategory,
            automaticBackupEnabled: widget.store.automaticBackupEnabled,
            lastBackupAt: widget.store.lastBackupAt,
            backupError: widget.store.backupError,
            backupOverdue: widget.store.backupOverdue,
            onConfigureAutomaticBackup: _configureAutomaticBackup,
            onDisableAutomaticBackup: _disableAutomaticBackup,
            onRunAutomaticBackup: _runAutomaticBackup),
        10 => SubscriptionsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openSubscriptionDialog,
            onDelete: _deleteSubscription,
            onEdit: _editSubscription,
            onActiveChanged: widget.store.setSubscriptionActive),
        11 => ShoppingPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openShoppingDialog,
            onEdit: _editShoppingItem,
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
        type: value.type,
        customInstitutionName: value.customInstitutionName,
        customIconKey: value.customIconKey,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a conta.');
    }
  }

  Future<void> _editAccountBalance(String id) async {
    final account =
        widget.store.accounts.where((item) => item.id == id).firstOrNull;
    if (account == null) return;
    final amount = await showDialog<int>(
        context: context,
        builder: (_) => AccountBalanceDialog(
            name: account.name,
            currentCents: FinancialRules.accountBalance(
                account, widget.store.transactions)));
    if (amount == null || !mounted) return;
    try {
      widget.store.setAccountCurrentBalance(id, amount);
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
    }
  }

  Future<void> _editAccount(String id) async {
    final account =
        widget.store.accounts.where((item) => item.id == id).firstOrNull;
    if (account == null) return;
    final currentBalance =
        FinancialRules.accountBalance(account, widget.store.transactions);
    final value = await showDialog<AccountInput>(
      context: context,
      builder: (_) => AccountDialog(
        account: account,
        currentBalanceCents: currentBalance,
      ),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.updateAccount(
        id: account.id,
        name: value.name,
        currentBalanceInCents: value.openingCents,
        institution: value.institution,
        type: value.type,
        customInstitutionName: value.customInstitutionName,
        customIconKey: value.customIconKey,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível editar a conta.');
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
      _showUndoDelete(SoftDeleteEntity.account, accountId,
          message: 'Conta excluída.');
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível excluir a conta.');
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final transaction = widget.store.transactions
        .where((item) => item.id == transactionId)
        .firstOrNull;
    if (transaction?.systemType == TransactionSystemType.cardPayment) {
      _showError('Estorne o pagamento pela fatura.');
      return;
    }
    final recurringSalary = transaction?.category.toLowerCase() == 'salário' &&
        widget.store.salarySchedules
            .any((item) => item.id == transaction?.seriesId);
    final confirmed = await _confirmDelete(
      title: 'Excluir lançamento?',
      message: recurringSalary
          ? 'Este salário pertence a uma recorrência. A ocorrência será excluída e os próximos salários deixarão de ser criados; os meses anteriores permanecem no histórico.'
          : 'O saldo e os relatórios serão recalculados imediatamente.',
    );
    if (confirmed) {
      final canceledSchedule = widget.store.deleteTransaction(transactionId);
      _showUndoDelete(SoftDeleteEntity.transaction, transactionId,
          message: 'Lançamento excluído.',
          canceledSalarySchedule: canceledSchedule);
    }
  }

  Future<void> _editTransaction(TransactionRecord item) async {
    if (item.systemType == TransactionSystemType.cardPayment) {
      _showError('Estorne o pagamento pela fatura.');
      return;
    }
    final input = await showDialog<TransactionEditResult>(
        context: context,
        builder: (_) => TransactionEditDialog(
              clock: widget.store.clock,
              item: item,
              accounts: [
                ...widget.store.activeAccounts,
                if (widget.store.accounts.any((account) =>
                    account.id == item.accountId && account.archivedAt != null))
                  widget.store.accounts
                      .firstWhere((account) => account.id == item.accountId),
                if (item.destinationAccountId != null &&
                    widget.store.accounts.any((account) =>
                        account.id == item.destinationAccountId &&
                        account.archivedAt != null))
                  widget.store.accounts.firstWhere(
                      (account) => account.id == item.destinationAccountId),
              ],
              categories: widget.store.financeCategories,
              subcategories: widget.store.financeSubcategories,
              tags: widget.store.tags,
              selectedTagIds: widget.store
                  .tagsForTransaction(item.id)
                  .map((t) => t.id)
                  .toSet(),
              onManageTags: () async {
                await showDialog<void>(
                  context: context,
                  builder: (_) => TagManagerDialog(store: widget.store),
                );
                return widget.store.tags;
              },
            ));
    if (input == null || !mounted) return;
    try {
      var applyToFuture = false;
      if (item.seriesId != null) {
        final scope = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Aplicar alteração'),
            content: Text(
                item.scheduleType == TransactionScheduleType.installment
                    ? 'Este lançamento pertence a um parcelamento.'
                    : 'Este lançamento pertence a uma recorrência.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'one'),
                  child: const Text('Somente esta')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, 'future'),
                  child: const Text('Esta e as próximas')),
            ],
          ),
        );
        if (scope == null || !mounted) return;
        applyToFuture = scope == 'future';
      }
      widget.store.updateTransaction(input.transaction,
          applyToFuture: applyToFuture, tagIds: input.tagIds);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento atualizado.')));
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
    }
  }

  Future<void> _manageAttachments(TransactionRecord item) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          AttachmentManagerDialog(store: widget.store, transaction: item),
    );
  }

  Future<void> _deleteBudget(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir orçamento?',
      message: 'O limite mensal desta categoria será removido.',
    );
    if (confirmed) {
      widget.store.deleteBudget(id);
      _showUndoDelete(SoftDeleteEntity.budget, id,
          message: 'Orçamento excluído.');
    }
  }

  Future<void> _cancelSalarySchedule(String id) async {
    final confirmed = await _confirmDelete(
        title: 'Cancelar salário recorrente?',
        message:
            'Novos meses não serão criados. Movimentações já registradas permanecem no histórico.');
    if (confirmed) widget.store.cancelSalarySchedule(id);
  }

  Future<void> _deleteSubscription(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir assinatura?',
      message: 'A cobrança recorrente deixará de aparecer no calendário.',
    );
    if (confirmed) {
      widget.store.deleteSubscription(id);
      _showUndoDelete(SoftDeleteEntity.subscription, id,
          message: 'Assinatura excluída.');
    }
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

  void _showUndoDelete(SoftDeleteEntity entity, String id,
      {required String message, SalarySchedule? canceledSalarySchedule}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => widget.store.restoreDeletedRecord(
            entity,
            id,
            canceledSalarySchedule: canceledSalarySchedule,
          ),
        ),
      ));
  }

  Future<void> _openTransactionDialog({
    TransactionType initialType = TransactionType.expense,
  }) async {
    if (widget.store.accounts.isEmpty) {
      _showError('Crie uma conta antes de registrar uma transação.');
      return;
    }
    if (initialType == TransactionType.transfer &&
        widget.store.accounts.length < 2) {
      _showError('Cadastre uma segunda conta para fazer transferências.');
      return;
    }
    final value = await showDialog<TransactionInput>(
      context: context,
      builder: (_) => TransactionDialog(
        clock: widget.store.clock,
        initialType: initialType,
        accounts: widget.store.activeAccounts,
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
    if (confirmed) {
      widget.store.deleteTask(id);
      _showUndoDelete(SoftDeleteEntity.task, id, message: 'Tarefa excluída.');
    }
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
        imagePath: value.imagePath,
        description: value.description,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o item.');
    }
  }

  Future<void> _editShoppingItem(ShoppingItem item) async {
    final value = await showDialog<ShoppingInput>(
      context: context,
      builder: (_) => ShoppingDialog(item: item),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.updateShoppingItem(
        id: item.id,
        name: value.name,
        quantity: value.quantity,
        estimatedUnitPriceInCents: value.estimatedUnitPriceInCents,
        priority: value.priority,
        isPurchased: item.isPurchased,
        imagePath: value.imagePath,
        description: value.description,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível atualizar o item.');
    }
  }

  Future<void> _deleteShoppingItem(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir item?',
      message: 'O item será removido da lista de desejos/compras.',
    );
    if (confirmed) {
      widget.store.deleteShoppingItem(id);
      _showUndoDelete(SoftDeleteEntity.shoppingItem, id,
          message: 'Item excluído.');
    }
  }

  Future<void> _openProfileDialog() async {
    final value = await showDialog<ProfileInput>(
      context: context,
      builder: (_) => ProfileDialog(
        initialName: widget.store.profileName,
        initialIncomeInCents: widget.store.profileIncomeInCents,
        initialPhotoPath: widget.store.profilePhotoPath,
      ),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.saveProfile(
        name: value.name,
        incomeInCents: value.incomeInCents,
        photoPath: value.photoPath,
      );
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar o perfil.');
    }
  }

  Future<void> _openFinancialGoalDialog() async {
    final value = await showDialog<FinancialGoalInput>(
      context: context,
      builder: (_) => FinancialGoalDialog(
          clock: widget.store.clock,
          categories: widget.store.goalCategories,
          onCreateCategory: widget.store.addGoalCategory),
    );
    if (value == null || !mounted) return;
    try {
      widget.store.addFinancialGoal(
        name: value.name,
        targetInCents: value.targetInCents,
        initialSavedInCents: value.initialSavedInCents,
        deadline: value.deadline,
        iconKey: value.iconKey,
        category: value.category,
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
    if (confirmed) {
      widget.store.deleteFinancialGoal(id);
      _showUndoDelete(SoftDeleteEntity.financialGoal, id,
          message: 'Meta excluída.');
    }
  }

  Future<void> _deleteInvestment(String id) async {
    final confirmed = await _confirmDelete(
      title: 'Excluir investimento?',
      message: 'A posição manual será removida da carteira consolidada.',
    );
    if (confirmed) {
      widget.store.deleteInvestment(id);
      _showUndoDelete(SoftDeleteEntity.investment, id,
          message: 'Investimento excluído.');
    }
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
        categories: widget.store.financeCategories,
        subcategories: widget.store.financeSubcategories,
        clock: widget.store.clock,
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
        category: value.category,
        subcategory: value.subcategory,
        purchasedOn: value.purchasedOn,
      );
    } on ArgumentError catch (error) {
      if (error.message.toString().contains('altera faturas já fechadas')) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Alterar faturas fechadas?'),
            content: const Text(
                'Esta compra antiga muda o valor de uma ou mais faturas já fechadas. Confira as faturas antes de continuar.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar compra'),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          widget.store.addCardPurchase(
            cardId: value.cardId,
            description: value.description,
            amountInCents: value.amountInCents,
            installments: value.installments,
            category: value.category,
            subcategory: value.subcategory,
            purchasedOn: value.purchasedOn,
            allowClosedInvoiceChange: true,
          );
        }
        return;
      }
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a compra.');
    }
  }

  Future<void> _manageCardPurchaseInstallments(CardPurchase purchase) async {
    final paidInstallments = await showDialog<Set<int>>(
      context: context,
      builder: (_) => CardInstallmentPaymentsDialog(
        purchase: purchase,
        hideValues: _hideValues,
      ),
    );
    if (paidInstallments == null || !mounted) return;
    try {
      widget.store.setCardPurchaseInstallmentsPaid(
        purchase.id,
        paidInstallments,
      );
    } on ArgumentError catch (error) {
      _showError(error.message?.toString() ?? 'Não foi possível salvar.');
    }
  }

  Future<void> _payCardInvoice(CreditCard card, int year, int month) async {
    if (widget.store.accounts.isEmpty) {
      _showError('Cadastre uma conta antes de pagar a fatura.');
      return;
    }
    final invoice = widget.store.cardInvoices
        .where((item) =>
            item.cardId == card.id &&
            item.referenceYear == year &&
            item.referenceMonth == month)
        .firstOrNull;
    final paid = invoice == null
        ? 0
        : widget.store.cardInvoicePayments
            .where((item) => item.invoiceId == invoice.id)
            .fold<int>(0, (sum, item) => sum + item.amountInCents);
    final remaining = CardInvoiceRules.remainingForPeriod(
      card,
      widget.store.cardPurchases,
      year,
      month,
      actualPaymentsInCents: paid,
    );
    if (remaining == 0) return;
    var accountId = widget.store.accounts.first.id;
    var enteredAmount =
        '${remaining ~/ 100},${(remaining % 100).toString().padLeft(2, '0')}';
    final result = await showDialog<({String accountId, int cents})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pagar fatura ${month.toString().padLeft(2, '0')}/$year'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Restante: ${FinancialRules.formatBrl(remaining)}'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: accountId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Conta de pagamento'),
            items: widget.store.accounts
                .map((account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ))
                .toList(),
            onChanged: (value) => accountId = value!,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: enteredAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor (R\$)'),
            onChanged: (value) => enteredAmount = value,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final cents = parseMoney(enteredAmount);
              if (cents == null || cents <= 0 || cents > remaining) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
                  content: Text('Informe um valor até o restante da fatura.'),
                ));
                return;
              }
              Navigator.pop(
                  dialogContext, (accountId: accountId, cents: cents));
            },
            child: const Text('Confirmar pagamento'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      widget.store.payCardInvoice(
        cardId: card.id,
        referenceYear: year,
        referenceMonth: month,
        accountId: result.accountId,
        amountInCents: result.cents,
      );
      _showError('Pagamento registrado.');
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
    }
  }

  Future<void> _reverseCardInvoicePayment(String paymentId) async {
    final confirmed = await _confirmDelete(
      title: 'Estornar pagamento?',
      message: 'O valor voltará ao saldo da conta e à fatura pendente.',
    );
    if (!confirmed || !mounted) return;
    try {
      widget.store.reverseCardInvoicePayment(paymentId);
      _showError('Pagamento estornado.');
    } on Object catch (error) {
      _showError('Não foi possível estornar: $error');
    }
  }

  Future<void> _openInvestmentDialog() => _showInvestmentDialog();

  Future<void> _editInvestment(String id) async {
    final position =
        widget.store.investments.where((item) => item.id == id).firstOrNull;
    if (position != null) await _showInvestmentDialog(position);
  }

  Future<void> _showInvestmentDialog([InvestmentPosition? position]) async {
    final value = await showDialog<InvestmentInput>(
      context: context,
      builder: (_) => InvestmentDialog(
        clock: widget.store.clock,
        position: position,
      ),
    );
    if (value == null || !mounted) return;
    try {
      if (position == null) {
        widget.store.addInvestment(
          name: value.name,
          type: value.type,
          investedAmountInCents: value.investedAmountInCents,
          currentValueInCents: value.currentValueInCents,
          fixedIncomeType: value.fixedIncomeType,
          institutionName: value.institutionName,
          maturityDate: value.maturityDate,
          quotedRateBasisPoints: value.quotedRateBasisPoints,
          quotedRatePeriod: value.quotedRatePeriod,
          yieldPaymentDay: value.yieldPaymentDay,
        );
      } else {
        widget.store.updateInvestment(
          id: position.id,
          name: value.name,
          type: value.type,
          investedAmountInCents: value.investedAmountInCents,
          currentValueInCents: value.currentValueInCents,
          fixedIncomeType: value.fixedIncomeType,
          institutionName: value.institutionName,
          maturityDate: value.maturityDate,
          quotedRateBasisPoints: value.quotedRateBasisPoints,
          quotedRatePeriod: value.quotedRatePeriod,
          yieldPaymentDay: value.yieldPaymentDay,
        );
      }
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
      builder: (_) => BudgetDialog(
          categories: categories,
          onCreateCategory: widget.store.addFinanceCategory),
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

  Future<void> _openSubscriptionDialog() => _showSubscriptionDialog();

  Future<void> _editSubscription(String id) async {
    final item =
        widget.store.subscriptions.where((value) => value.id == id).firstOrNull;
    if (item != null) await _showSubscriptionDialog(item);
  }

  Future<void> _showSubscriptionDialog([Subscription? existing]) async {
    final categories = widget.store.financeCategories
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.name)
        .toList();
    final value = await showDialog<SubscriptionInput>(
      context: context,
      builder: (_) =>
          SubscriptionDialog(categories: categories, subscription: existing),
    );
    if (value == null || !mounted) return;
    try {
      if (existing == null) {
        widget.store.addSubscription(
            name: value.name,
            amountInCents: value.amountInCents,
            billingDay: value.billingDay,
            category: value.category);
      } else {
        widget.store.updateSubscription(
            id: existing.id,
            name: value.name,
            amountInCents: value.amountInCents,
            billingDay: value.billingDay,
            category: value.category);
      }
    } on ArgumentError catch (error) {
      _showError(
          error.message?.toString() ?? 'Não foi possível salvar a assinatura.');
    }
  }

  Future<void> _configureAutomaticBackup() async {
    String? selected;
    try {
      selected = await widget.store.chooseAutomaticBackupFolder();
      if (selected == null) return;
      if (!mounted) {
        await widget.store.discardAutomaticBackupFolder(selected);
        return;
      }
      final password = await _backupPasswordDialog(
        title: 'Senha para backups automáticos',
        confirm: true,
      );
      if (password == null || !mounted) {
        await widget.store.discardAutomaticBackupFolder(selected);
        return;
      }
      var interval = widget.store.backupIntervalDays;
      var retention = widget.store.backupRetention;
      var onClose = widget.store.backupOnClose;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, change) => AlertDialog(
            title: const Text('Backup automático'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue:
                      [1, 3, 7, 14, 30].contains(interval) ? interval : 7,
                  decoration:
                      const InputDecoration(labelText: 'Intervalo em dias'),
                  items: [1, 3, 7, 14, 30]
                      .map((days) => DropdownMenuItem(
                          value: days, child: Text('$days dia(s)')))
                      .toList(),
                  onChanged: (value) => change(() => interval = value ?? 7),
                ),
                DropdownButtonFormField<int>(
                  initialValue:
                      [1, 3, 5, 10].contains(retention) ? retention : 3,
                  decoration:
                      const InputDecoration(labelText: 'Cópias mantidas'),
                  items: [1, 3, 5, 10]
                      .map((count) =>
                          DropdownMenuItem(value: count, child: Text('$count')))
                      .toList(),
                  onChanged: (value) => change(() => retention = value ?? 3),
                ),
                SwitchListTile(
                  value: onClose,
                  title: const Text('Também ao fechar'),
                  subtitle: const Text(
                      'No Android, o sistema pode encerrar o app sem aviso.'),
                  onChanged: (value) => change(() => onClose = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ativar'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true) {
        await widget.store.discardAutomaticBackupFolder(selected);
        return;
      }
      await widget.store.configureAutomaticBackup(
          enabled: true,
          intervalDays: interval,
          retention: retention,
          onClose: onClose,
          password: password,
          selectedFolder: selected);
      if (mounted) _showError('Backup automático ativado.');
    } on Object catch (error) {
      if (selected != null) {
        await widget.store.discardAutomaticBackupFolder(selected);
      }
      if (mounted) _showError('Não foi possível configurar o backup: $error');
    }
  }

  Future<void> _disableAutomaticBackup() async {
    await widget.store.configureAutomaticBackup(
        enabled: false,
        intervalDays: widget.store.backupIntervalDays,
        retention: widget.store.backupRetention,
        onClose: widget.store.backupOnClose);
  }

  Future<void> _runAutomaticBackup() async {
    await widget.store.runAutomaticBackup(force: true);
    if (mounted) {
      _showError(widget.store.backupError?.isNotEmpty == true
          ? 'Falha no backup: ${widget.store.backupError}'
          : 'Backup automático salvo.');
    }
  }

  Future<void> _exportEncryptedBackup() async {
    final password = await _backupPasswordDialog(
      title: 'Criar backup protegido',
      confirm: true,
    );
    if (password == null) return;
    try {
      if (Platform.isAndroid) {
        final file = await widget.store.exportEncryptedBackup(password);
        final saved = await FilePicker.platform.saveFile(
          dialogTitle: 'Salvar backup do Organiza',
          fileName: file.uri.pathSegments.last,
          type: FileType.custom,
          allowedExtensions: ['organizabak'],
          bytes: await file.readAsBytes(),
        );
        if (mounted && saved != null) _showError('Backup exportado.');
      } else {
        final selected = await FilePicker.platform.saveFile(
          dialogTitle: 'Salvar backup do Organiza',
          fileName: 'organiza.organizabak',
          type: FileType.custom,
          allowedExtensions: ['organizabak'],
        );
        if (selected == null) return;
        final file = await widget.store
            .exportEncryptedBackup(password, destination: File(selected));
        if (mounted) _showError('Backup salvo em ${file.path}');
      }
    } on Object catch (error) {
      if (mounted) _showError('Não foi possível criar o backup: $error');
    }
  }

  Future<void> _restoreEncryptedBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['organizabak', 'backup', 'json'],
      withData: false,
    );
    final selectedPath = result?.files.single.path;
    if (selectedPath == null) return;
    final password = await _backupPasswordDialog(
      title: 'Restaurar backup protegido',
    );
    if (password == null) return;
    try {
      final preview =
          await widget.store.prepareBackup(File(selectedPath), password);
      if (!mounted) {
        await preview.dispose();
        return;
      }
      final counts = preview.counts;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirmar restauração'),
          content: Text(
            'Backup de ${preview.createdAt ?? 'data desconhecida'} '
            '(schema ${preview.schemaVersion}).\n'
            '${counts['accounts'] ?? 0} contas, '
            '${counts['transactions'] ?? 0} transações e '
            '${counts['credit_cards'] ?? 0} cartões.\n\n'
            '${preview.isLegacy ? 'Formato antigo: imagens não acompanham este arquivo.\n\n' : ''}'
            'Os dados atuais serão substituídos. Uma cópia de segurança será mantida.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Restaurar')),
          ],
        ),
      );
      if (confirmed != true) {
        await preview.dispose();
        return;
      }
      final safetyCopy = await widget.store.confirmBackup(preview);
      if (mounted) {
        _showError(
            'Backup restaurado. Uma cópia do estado anterior foi salva em ${safetyCopy.path}.');
      }
    } on Object catch (error) {
      if (mounted) _showError('Não foi possível restaurar o backup: $error');
    }
  }

  Future<String?> _backupPasswordDialog({
    required String title,
    bool confirm = false,
  }) async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  helperText: 'Use pelo menos 8 caracteres.',
                ),
              ),
              if (confirm)
                TextField(
                  controller: confirmationController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final password = passwordController.text;
                if (password.length < 8 ||
                    (confirm && password != confirmationController.text)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                          confirm && password != confirmationController.text
                              ? 'As senhas não conferem.'
                              : 'A senha deve ter pelo menos 8 caracteres.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, password);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    } finally {
      passwordController.dispose();
      confirmationController.dispose();
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
        purchases: widget.store.cardPurchases.where((item) =>
            item.purchasedOn.year == month.year &&
            item.purchasedOn.month == month.month),
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
    required this.profileName,
    required this.profilePhotoPath,
    required this.onSelect,
    required this.onCollapse,
  });

  final bool collapsed;
  final int selected;
  final List<_PageDefinition> pages;
  final String profileName;
  final String? profilePhotoPath;
  final ValueChanged<int> onSelect;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final dark = parentTheme.brightness == Brightness.dark;
    final sidebarBorder =
        dark ? const Color(0xFF292B31) : const Color(0xFFE0E1EA);
    final sidebarText =
        dark ? const Color(0xFFF7F3EE) : const Color(0xFF292832);
    final sidebarMuted =
        dark ? const Color(0xFFA9A6AD) : const Color(0xFF747382);
    final sidebarSurface =
        dark ? const Color(0xFF101114) : const Color(0xFFF0F1F7);
    final sidebarCard =
        dark ? const Color(0xFF1B1C21) : const Color(0xFFE6E7F0);
    final sidebarTheme = parentTheme.copyWith(
      dividerColor: sidebarBorder,
      colorScheme: parentTheme.colorScheme.copyWith(
        primary: parentTheme.colorScheme.primary,
        onPrimary: dark ? const Color(0xFF17110A) : Colors.white,
        surface: sidebarSurface,
        onSurface: sidebarText,
        onSurfaceVariant: sidebarMuted,
      ),
    );
    return Theme(
      data: sidebarTheme,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: collapsed ? 72 : 224,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF18191D), Color(0xFF0E0F11)]
                : const [Color(0xFFF6F7FB), Color(0xFFE9EAF3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sidebarBorder),
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
                      Text(
                        'ORGANIZA',
                        style: TextStyle(
                          color: sidebarText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                  child: ListView(padding: EdgeInsets.zero, children: [
                _section(context, [0]),
                _label(context, 'FINANÇAS'),
                _section(context, [1, 2, 3, 5, 10]),
                _label(context, 'ORGANIZAÇÃO'),
                _section(context, [6, 7, 11]),
                _label(context, 'ANÁLISE'),
                _section(context, [8]),
              ])),
              if (!collapsed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                  child: Material(
                    color: sidebarCard,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      onTap: () => onSelect(9),
                      borderRadius: BorderRadius.circular(13),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: dark
                                  ? const Color(0xFF3B473F)
                                  : const Color(0xFFD8D9E5),
                              backgroundImage:
                                  LocalImageService.exists(profilePhotoPath)
                                      ? FileImage(LocalImageService.fileFor(
                                          profilePhotoPath!))
                                      : null,
                              child: !LocalImageService.exists(profilePhotoPath)
                                  ? Icon(Icons.person_outline_rounded,
                                      size: 16, color: sidebarText)
                                  : null,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      profileName.isEmpty
                                          ? 'Perfil local'
                                          : profileName,
                                      style: TextStyle(
                                          color: sidebarText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('Somente neste dispositivo',
                                      style: TextStyle(
                                          color: sidebarMuted, fontSize: 10.5)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: sidebarMuted, size: 17),
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
                      foregroundColor: sidebarMuted,
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

  Widget _label(BuildContext context, String text) => collapsed
      ? const SizedBox(height: 18)
      : Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );

  Widget _section(BuildContext context, List<int> indices) => Column(
        children: indices.map((index) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          final sidebarText =
              dark ? const Color(0xFFF7F3EE) : const Color(0xFF292832);
          final sidebarMuted =
              dark ? const Color(0xFFA9A6AD) : const Color(0xFF747382);
          final activeBackground =
              dark ? const Color(0xFF3A250D) : const Color(0xFFE7E6FF);
          final activeText =
              dark ? const Color(0xFFFFD7A1) : const Color(0xFF3B3272);
          final page = pages[index];
          final active = selected == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
            child: Tooltip(
              message: collapsed ? page.label : '',
              child: Material(
                color: active ? activeBackground : Colors.transparent,
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
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        OrganizaIcon(
                          page.icon,
                          size: 19,
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : sidebarMuted,
                        ),
                        if (!collapsed) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              page.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? activeText : sidebarText,
                              ),
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
        results.add(_SearchResult(
            Icons.account_balance_outlined,
            account.name,
            'Conta · ${institutionName(account.institution, account.customInstitutionName)}',
            2));
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
            'Orçamento mensal', 6));
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
  final OrganizaIconName icon;
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
