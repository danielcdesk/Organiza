part of 'organiza_app.dart';

extension _OrganizaShellPart0 on _OrganizaShellState {
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
            title: Text(_pageDefinition(_page).label),
            actions: [
              IconButton(
                tooltip: 'Buscar',
                onPressed: _openSearch,
                icon: const Icon(Icons.search_rounded),
              ),
              if (_page != AppRoute.overview)
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
                      backgroundImage: widget.store.profilePhotoPath != null &&
                              File(widget.store.profilePhotoPath!).existsSync()
                          ? FileImage(File(widget.store.profilePhotoPath!))
                          : null,
                      child: widget.store.profilePhotoPath == null ||
                              !File(widget.store.profilePhotoPath!).existsSync()
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
                    _mobileDrawerSection('INÍCIO', [AppRoute.overview]),
                    _mobileDrawerSection('FINANÇAS', [
                      AppRoute.finances,
                      AppRoute.accounts,
                      AppRoute.cards,
                      AppRoute.investments,
                      AppRoute.subscriptions
                    ]),
                    _mobileDrawerSection('ORGANIZAÇÃO', [
                      AppRoute.organization,
                      AppRoute.goals,
                      AppRoute.shopping
                    ]),
                    _mobileDrawerSection('ANÁLISE', [AppRoute.reports]),
                    _mobileDrawerSection('PREFERÊNCIAS', [AppRoute.settings]),
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
                    _setShellState(
                        () => _page = primaryPages[slot < 2 ? slot : slot - 1]);
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  String _mobileNavLabel(AppRoute route) => switch (route) {
        AppRoute.overview => 'Início',
        AppRoute.investments => 'Investir',
        AppRoute.organization => 'Organizar',
        AppRoute.shopping => 'Desejos',
        _ => _pageDefinition(route).label,
      };

  IconData _mobileMaterialIcon(AppRoute route) => switch (route) {
        AppRoute.overview => Icons.home_outlined,
        AppRoute.finances => Icons.swap_horiz_rounded,
        AppRoute.investments => Icons.insights_outlined,
        AppRoute.organization => Icons.checklist_rounded,
        AppRoute.reports => Icons.bar_chart_rounded,
        AppRoute.shopping => Icons.shopping_bag_outlined,
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

  Widget _mobileDrawerSection(String title, List<AppRoute> routes) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1))),
        for (final route in routes)
          ListTile(
              leading: OrganizaIcon(_pageDefinition(route).icon, size: 22),
              title: Text(_pageDefinition(route).label),
              selected: route == _page,
              onTap: () {
                Navigator.pop(context);
                _setShellState(() => _page = route);
              }),
      ]);

  Widget _buildPage() => switch (_page) {
        AppRoute.overview => DashboardPage(
            store: widget.store,
            hideValues: _hideValues,
            onNewTransaction: _openTransactionDialog,
            onOpenCards: () => _setShellState(() => _page = AppRoute.cards),
            onOpenTransactions: () =>
                _setShellState(() => _page = AppRoute.finances),
            onOpenGoals: () => _setShellState(() => _page = AppRoute.goals),
            onOpenReports: () => _setShellState(() => _page = AppRoute.reports),
            onOpenBudgets: () => _setShellState(() => _page = AppRoute.budgets),
            onOpenSubscriptions: () =>
                _setShellState(() => _page = AppRoute.subscriptions),
            onOpenAccounts: () =>
                _setShellState(() => _page = AppRoute.accounts),
            onOpenOrganization: () =>
                _setShellState(() => _page = AppRoute.organization),
            onNewAccount: _openAccountDialog,
            onToggleValues: _toggleValues,
            onNewIncome: () =>
                _openTransactionDialog(initialType: TransactionType.income),
            onTransfer: () =>
                _openTransactionDialog(initialType: TransactionType.transfer),
          ),
        AppRoute.finances => TransactionsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openTransactionDialog,
            onDelete: _deleteTransaction,
            onSettledChanged: widget.store.setTransactionSettled,
            onEdit: _editTransaction,
          ),
        AppRoute.accounts => AccountsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openAccountDialog,
            onDelete: _deleteAccount,
            onEditBalance: _editAccountBalance,
            onEdit: _editAccount,
          ),
        AppRoute.cards => CardsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAddCard: _openCardDialog,
            onAddPurchase: _openCardPurchaseDialog,
            onEditCard: _editCard,
            onDeleteCard: _deleteCard,
            onEditPurchase: _editCardPurchase,
            onDeletePurchase: _deleteCardPurchase,
            onPayInvoice: _payCardInvoice,
            onReverseInvoicePayment: _reverseCardInvoicePayment,
          ),
        AppRoute.budgets => PlanningPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openTaskDialog,
            onDeleteTask: _deleteTask,
            onAddBudget: _openBudgetDialog,
            onDeleteBudget: _deleteBudget,
            onCancelSalary: _cancelSalarySchedule,
            budgetFirst: true),
        AppRoute.investments => InvestmentsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openInvestmentDialog,
            onEdit: _editInvestment,
            onDelete: _deleteInvestment,
          ),
        AppRoute.organization => PlanningPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openTaskDialog,
            onDeleteTask: _deleteTask,
            onAddBudget: _openBudgetDialog,
            onDeleteBudget: _deleteBudget,
            onCancelSalary: _cancelSalarySchedule,
          ),
        AppRoute.goals => GoalsPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openFinancialGoalDialog,
            onContribute: _openGoalContributionDialog,
            onDelete: _deleteFinancialGoal,
          ),
        AppRoute.reports => ReportsPage(
            store: widget.store,
            hideValues: _hideValues,
            onExport: _exportReport,
          ),
        AppRoute.settings => SettingsPage(
            onThemeChanged: widget.onThemeChanged,
            themePreference: widget.store.themePreference,
            quickPages: widget.store.mobileQuickPages,
            onQuickPagesChanged: widget.store.updateMobileQuickPages,
            profileName: widget.store.profileName,
            profileIncomeInCents: widget.store.profileIncomeInCents,
            profilePhotoPath: widget.store.profilePhotoPath,
            onEditProfile: _openProfileDialog,
            onExportBackup: _exportEncryptedBackup,
            onRestoreBackup: _restoreEncryptedBackup,
            remindersEnabled: widget.store.remindersEnabled,
            reminderDaysAhead: widget.store.reminderDaysAhead,
            reminderHour: widget.store.reminderHour,
            reminderMinute: widget.store.reminderMinute,
            onRemindersChanged: (value) async {
              final granted = await widget.store.setRemindersEnabled(value);
              if (!granted && mounted) {
                _showError('A permissão de notificações não foi concedida.');
              }
            },
            onReminderPreferencesChanged:
                widget.store.updateReminderPreferences,
            appLockEnabled: widget.store.appLockEnabled,
            appLockTimeoutMinutes: widget.store.appLockTimeoutMinutes,
            lockOnWindowHide: widget.store.lockOnWindowHide,
            onAppLockPreferencesChanged: (
                {required enabled, timeoutMinutes, onWindowHide}) {
              widget.store.updateAppLockPreferences(
                enabled: enabled,
                timeoutMinutes:
                    timeoutMinutes ?? widget.store.appLockTimeoutMinutes,
                onWindowHide: onWindowHide ?? widget.store.lockOnWindowHide,
              );
            }),
        AppRoute.subscriptions => SubscriptionsPage(
            store: widget.store,
            onAdd: _openSubscriptionDialog,
            onDelete: _deleteSubscription,
            onEdit: _editSubscription,
            onActiveChanged: widget.store.setSubscriptionActive),
        AppRoute.shopping => ShoppingPage(
            store: widget.store,
            hideValues: _hideValues,
            onAdd: _openShoppingDialog,
            onDelete: _deleteShoppingItem,
          ),
      };
}
