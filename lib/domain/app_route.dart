/// Stable route identity for navigation and persisted quick-access shortcuts.
enum AppRoute {
  overview('overview', 0, 'Visão geral'),
  finances('finances', 1, 'Finanças'),
  accounts('accounts', 2, 'Contas'),
  cards('cards', 3, 'Cartões'),
  budgets('budgets', 4, 'Orçamento', quick: false),
  investments('investments', 5, 'Investimentos'),
  organization('organization', 6, 'Organização'),
  goals('goals', 7, 'Metas'),
  reports('reports', 8, 'Relatórios'),
  settings('settings', 9, 'Configurações', quick: false),
  subscriptions('subscriptions', 10, 'Assinaturas'),
  shopping('shopping', 11, 'Lista de desejos');

  const AppRoute(this.id, this.legacyIndex, this.label, {this.quick = true});

  final String id;
  final int legacyIndex;
  final String label;
  final bool quick;

  static AppRoute? fromId(String id) {
    for (final route in values) {
      if (route.id == id) return route;
    }
    return null;
  }

  /// Legacy index 4 was historically normalized to route 6 by the app.
  static AppRoute? fromLegacyIndex(int index) => switch (index) {
        4 => organization,
        0 => overview,
        1 => finances,
        2 => accounts,
        3 => cards,
        5 => investments,
        6 => organization,
        7 => goals,
        8 => reports,
        9 => settings,
        10 => subscriptions,
        11 => shopping,
        _ => null,
      };
}
