part of 'organiza_app.dart';

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
  final AppRoute selected;
  final List<_PageDefinition> pages;
  final String profileName;
  final String? profilePhotoPath;
  final ValueChanged<AppRoute> onSelect;
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
        primary: OrganizaTheme.orange,
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
                _section(context, [AppRoute.overview]),
                _label(context, 'FINANÇAS'),
                _section(context, [
                  AppRoute.finances,
                  AppRoute.accounts,
                  AppRoute.cards,
                  AppRoute.investments,
                  AppRoute.subscriptions
                ]),
                _label(context, 'ORGANIZAÇÃO'),
                _section(context,
                    [AppRoute.organization, AppRoute.goals, AppRoute.shopping]),
                _label(context, 'ANÁLISE'),
                _section(context, [AppRoute.reports]),
              ])),
              if (!collapsed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                  child: Material(
                    color: sidebarCard,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      onTap: () => onSelect(AppRoute.settings),
                      borderRadius: BorderRadius.circular(13),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: dark
                                  ? const Color(0xFF3B473F)
                                  : const Color(0xFFD8D9E5),
                              backgroundImage: profilePhotoPath != null &&
                                      File(profilePhotoPath!).existsSync()
                                  ? FileImage(File(profilePhotoPath!))
                                  : null,
                              child: profilePhotoPath == null ||
                                      !File(profilePhotoPath!).existsSync()
                                  ? Icon(Icons.person_outline_rounded,
                                      size: 16, color: sidebarText)
                                  : null,
                            ),
                            SizedBox(width: 9),
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
                                  SizedBox(height: 2),
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
              _section(context, [AppRoute.settings]),
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

  Widget _section(BuildContext context, List<AppRoute> routes) => Column(
        children: routes.map((route) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          final sidebarText =
              dark ? const Color(0xFFF7F3EE) : const Color(0xFF292832);
          final sidebarMuted =
              dark ? const Color(0xFFA9A6AD) : const Color(0xFF747382);
          final activeBackground =
              dark ? const Color(0xFF3A250D) : const Color(0xFFE7E6FF);
          final activeText =
              dark ? const Color(0xFFFFD7A1) : const Color(0xFF3B3272);
          final page =
              pages.firstWhere((definition) => definition.route == route);
          final active = selected == route;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
            child: Tooltip(
              message: collapsed ? page.label : '',
              child: Material(
                color: active ? activeBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onSelect(route),
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
                        OrganizaIcon(
                          page.icon,
                          size: 19,
                          color: active ? OrganizaTheme.orange : sidebarMuted,
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
