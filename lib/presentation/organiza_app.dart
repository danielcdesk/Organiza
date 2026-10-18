import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import '../application/organiza_store.dart';
import '../domain/models.dart';
import '../domain/app_route.dart';
import '../domain/financial_rules.dart';
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
import 'app_lock_gate.dart';

part 'organiza_app_navigation.dart';
part 'organiza_app_account_actions.dart';
part 'organiza_app_activity_actions.dart';
part 'organiza_app_card_actions.dart';
part 'organiza_app_planning_actions.dart';
part 'organiza_app_backup_actions.dart';
part 'organiza_app_sidebar.dart';
part 'organiza_app_topbar.dart';
part 'organiza_app_search.dart';

class OrganizaApp extends StatefulWidget {
  const OrganizaApp({super.key, required this.store});

  final OrganizaStore store;

  @override
  State<OrganizaApp> createState() => _OrganizaAppState();
}

class _TransactionDeleteChoice {
  const _TransactionDeleteChoice(this.scope, {this.cancelSalary = false});
  final TransactionSeriesScope scope;
  final bool cancelSalary;
}

class _TransactionDeleteDialog extends StatefulWidget {
  const _TransactionDeleteDialog(
      {required this.isSeries, required this.isSalary});
  final bool isSeries;
  final bool isSalary;

  @override
  State<_TransactionDeleteDialog> createState() =>
      _TransactionDeleteDialogState();
}

class _TransactionDeleteDialogState extends State<_TransactionDeleteDialog> {
  TransactionSeriesScope _scope = TransactionSeriesScope.occurrence;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.isSalary ? 'Excluir salário' : 'Excluir lançamento?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.isSeries && !widget.isSalary)
            DropdownButtonFormField<TransactionSeriesScope>(
              initialValue: _scope,
              decoration: const InputDecoration(labelText: 'Aplicar em'),
              items: const [
                DropdownMenuItem(
                    value: TransactionSeriesScope.occurrence,
                    child: Text('Somente esta')),
                DropdownMenuItem(
                    value: TransactionSeriesScope.fromHere,
                    child: Text('Esta e as próximas')),
                DropdownMenuItem(
                    value: TransactionSeriesScope.entireSeries,
                    child: Text('Todas')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _scope = value);
              },
            )
          else
            Text(widget.isSalary
                ? 'Por padrão, apenas esta ocorrência será removida. Para parar os próximos salários, escolha cancelar a recorrência.'
                : 'O saldo e os relatórios serão recalculados.'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar')),
          if (widget.isSalary)
            TextButton(
                onPressed: () => Navigator.pop(
                    context,
                    const _TransactionDeleteChoice(
                        TransactionSeriesScope.occurrence,
                        cancelSalary: true)),
                child: const Text('Cancelar recorrência')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _TransactionDeleteChoice(_scope)),
              child: const Text('Excluir')),
        ],
      );
}

class _OrganizaAppState extends State<OrganizaApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == widget.store.themePreference,
      orElse: () => ThemeMode.dark,
    );
  }

  void _changeTheme(ThemeMode mode) {
    widget.store.saveThemePreference(mode.name);
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Organiza',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        themeMode: _themeMode,
        theme: OrganizaTheme.light(),
        darkTheme: OrganizaTheme.dark(),
        routes: {
          if (kDebugMode)
            '/debug/components': (_) => const DebugComponentCatalogPage(),
        },
        home: AppLockGate(
          store: widget.store,
          child: OrganizaShell(
            store: widget.store,
            onThemeChanged: _changeTheme,
          ),
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
  var _page = AppRoute.overview;
  var _collapsed = false;
  var _hideValues = false;
  var _isFullscreen = false;
  var _welcomeStarted = false;

  static const _pages = <_PageDefinition>[
    _PageDefinition(AppRoute.overview, OrganizaIconName.dashboard),
    _PageDefinition(AppRoute.finances, OrganizaIconName.transactions),
    _PageDefinition(AppRoute.accounts, OrganizaIconName.wallet),
    _PageDefinition(AppRoute.cards, OrganizaIconName.creditCard),
    _PageDefinition(AppRoute.budgets, OrganizaIconName.budget),
    _PageDefinition(AppRoute.investments, OrganizaIconName.investments),
    _PageDefinition(AppRoute.organization, OrganizaIconName.organization),
    _PageDefinition(AppRoute.goals, OrganizaIconName.goals),
    _PageDefinition(AppRoute.reports, OrganizaIconName.reports),
    _PageDefinition(AppRoute.settings, OrganizaIconName.settings),
    _PageDefinition(AppRoute.subscriptions, OrganizaIconName.subscriptions),
    _PageDefinition(AppRoute.shopping, OrganizaIconName.shopping),
  ];

  _PageDefinition _pageDefinition(AppRoute route) =>
      _pages.firstWhere((page) => page.route == route);

  @override
  void initState() {
    super.initState();
    _hideValues = widget.store.hideValuesPreference;
    widget.store.addListener(_refresh);
  }

  void _toggleValues() {
    setState(() => _hideValues = !_hideValues);
    widget.store.saveHideValuesPreference(_hideValues);
  }

  @override
  void dispose() {
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
    if (mounted) setState(() => _page = AppRoute.overview);
  }

  void _setShellState(VoidCallback callback) => setState(callback);

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
              onInvoke: (_) => setState(() => _page = AppRoute.settings)),
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
                          onSelect: (route) => setState(() => _page = route),
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
                                title: _pageDefinition(_page).label,
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
}
