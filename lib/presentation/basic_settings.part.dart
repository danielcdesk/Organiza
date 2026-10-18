part of 'basic_pages.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage(
      {super.key,
      required this.onThemeChanged,
      this.themePreference = 'dark',
      required this.quickPages,
      required this.onQuickPagesChanged,
      required this.profileName,
      required this.profileIncomeInCents,
      this.profilePhotoPath,
      required this.onEditProfile,
      required this.onExportBackup,
      required this.onRestoreBackup,
      required this.remindersEnabled,
      required this.reminderDaysAhead,
      required this.reminderHour,
      required this.reminderMinute,
      required this.onRemindersChanged,
      required this.onReminderPreferencesChanged,
      required this.appLockEnabled,
      required this.appLockTimeoutMinutes,
      required this.lockOnWindowHide,
      required this.onAppLockPreferencesChanged});

  final ValueChanged<ThemeMode> onThemeChanged;
  final String themePreference;
  final List<AppRoute> quickPages;
  final ValueChanged<List<AppRoute>> onQuickPagesChanged;
  final String profileName;
  final int profileIncomeInCents;
  final String? profilePhotoPath;
  final VoidCallback onEditProfile;
  final Future<void> Function() onExportBackup;
  final Future<void> Function() onRestoreBackup;
  final bool remindersEnabled;
  final int reminderDaysAhead;
  final int reminderHour;
  final int reminderMinute;
  final Future<void> Function(bool) onRemindersChanged;
  final Future<void> Function({int? daysAhead, int? hour, int? minute})
      onReminderPreferencesChanged;
  final bool appLockEnabled;
  final int appLockTimeoutMinutes;
  final bool lockOnWindowHide;
  final void Function(
      {required bool enabled,
      int? timeoutMinutes,
      bool? onWindowHide}) onAppLockPreferencesChanged;
  static const _quickRoutes = <AppRoute>[
    AppRoute.overview,
    AppRoute.finances,
    AppRoute.accounts,
    AppRoute.cards,
    AppRoute.investments,
    AppRoute.organization,
    AppRoute.goals,
    AppRoute.reports,
    AppRoute.subscriptions,
    AppRoute.shopping,
  ];

  @override
  Widget build(BuildContext context) => _Page(
        heading: const PageHeading(
          eyebrow: 'PREFERÊNCIAS',
          title: 'Configurações',
          description: 'Aparência e parâmetros locais do Organiza.',
        ),
        content: Column(
          children: [
            if (MediaQuery.sizeOf(context).width >= 600) ...[
              Panel(
                title: 'Perfil local',
                subtitle:
                    'Uma identificação rápida, salva somente neste aparelho.',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .15),
                      backgroundImage:
                          LocalImageService.exists(profilePhotoPath)
                              ? FileImage(File(profilePhotoPath!))
                              : null,
                      child: LocalImageService.exists(profilePhotoPath)
                          ? null
                          : Icon(Icons.person_outline_rounded,
                              color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileName.isEmpty
                                ? 'Ainda não configurado'
                                : profileName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profileIncomeInCents == 0
                                ? 'Adicione seu nome, renda e foto.'
                                : 'Renda mensal: ${FinancialRules.formatBrl(profileIncomeInCents)}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onEditProfile,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label:
                          Text(profileName.isEmpty ? 'Criar perfil' : 'Editar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Panel(
              title: 'Geral',
              child: DataListRow(
                icon: Icons.payments_outlined,
                title: 'Moeda e formato',
                subtitle: 'BRL · R\$ · dd/MM/yyyy',
                value: 'Brasil',
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              title: 'Aparência',
              subtitle: 'Escolha como o aplicativo deve ser exibido',
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _themeButton(Icons.brightness_auto_outlined, 'Sistema',
                      ThemeMode.system),
                  _themeButton(
                      Icons.light_mode_outlined, 'Claro', ThemeMode.light),
                  _themeButton(
                      Icons.dark_mode_outlined, 'Escuro', ThemeMode.dark),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (MediaQuery.sizeOf(context).width < 600) ...[
              Panel(
                  title: 'Acesso rápido no celular',
                  subtitle:
                      'Escolha quatro áreas para a barra inferior. O botão Nova transação permanece no centro.',
                  child: Column(
                      children: List.generate(
                          4,
                          (slot) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: DropdownButtonFormField<AppRoute>(
                                    isExpanded: true,
                                    key: ValueKey(
                                        'quick-$slot-${quickPages[slot].id}'),
                                    initialValue: quickPages[slot],
                                    decoration: InputDecoration(
                                        labelText: 'Atalho ${slot + 1}'),
                                    items: _quickRoutes
                                        .where((route) =>
                                            route == quickPages[slot] ||
                                            !quickPages.contains(route))
                                        .map((route) => DropdownMenuItem(
                                            value: route,
                                            child: Text(route.label)))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      final next =
                                          List<AppRoute>.of(quickPages);
                                      next[slot] = value;
                                      onQuickPagesChanged(next);
                                    }),
                              )))),
              const SizedBox(height: 14),
            ],
            Panel(
              title: 'Backup local',
              subtitle:
                  'Crie um arquivo protegido por senha para recuperar seus dados em outro dispositivo.',
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onExportBackup(),
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('Criar backup'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onRestoreBackup(),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restaurar backup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              title: 'Lembretes locais',
              subtitle:
                  'Avisos neste dispositivo para pendências, faturas e assinaturas.',
              child: Column(children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativar notificações'),
                  subtitle:
                      const Text('A permissão só será solicitada ao ativar.'),
                  value: remindersEnabled,
                  onChanged: (value) => onRemindersChanged(value),
                ),
                if (remindersEnabled) ...[
                  DropdownButtonFormField<int>(
                    initialValue: reminderDaysAhead,
                    decoration:
                        const InputDecoration(labelText: 'Antecedência'),
                    items: const [0, 1, 3]
                        .map((days) => DropdownMenuItem(
                            value: days,
                            child: Text(days == 0
                                ? 'No dia do vencimento'
                                : '$days dias antes')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onReminderPreferencesChanged(daysAhead: value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                              hour: reminderHour, minute: reminderMinute));
                      if (selected != null) {
                        onReminderPreferencesChanged(
                            hour: selected.hour, minute: selected.minute);
                      }
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                        'Horário: ${TimeOfDay(hour: reminderHour, minute: reminderMinute).format(context)}'),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            Panel(
              title: 'Bloqueio do aplicativo',
              subtitle:
                  'Use a biometria ou a credencial do dispositivo ao abrir ou retornar.',
              child: Column(children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bloquear o Organiza'),
                  value: appLockEnabled,
                  onChanged: (value) =>
                      onAppLockPreferencesChanged(enabled: value),
                ),
                if (appLockEnabled) ...[
                  DropdownButtonFormField<int>(
                    initialValue: appLockTimeoutMinutes,
                    decoration: const InputDecoration(
                        labelText: 'Bloquear ao voltar após'),
                    items: const [0, 1, 5, 15, 30]
                        .map((minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text(minutes == 0
                                ? 'Qualquer tempo'
                                : '$minutes minutos')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onAppLockPreferencesChanged(
                            enabled: true, timeoutMinutes: value);
                      }
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bloquear ao ocultar a janela (Windows)'),
                    value: lockOnWindowHide,
                    onChanged: (value) => onAppLockPreferencesChanged(
                        enabled: true, onWindowHide: value),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            const Panel(
              title: 'Privacidade',
              child: DataListRow(
                icon: Icons.shield_outlined,
                title: 'Dados somente neste dispositivo',
                subtitle: 'Sem login online, analytics ou telemetria.',
                value: 'Local',
              ),
            ),
          ],
        ),
      );

  Widget _themeButton(IconData icon, String label, ThemeMode mode) =>
      OutlinedButton.icon(
        onPressed: () => onThemeChanged(mode),
        icon: Icon(
            themePreference == mode.name ? Icons.check_circle_outline : icon),
        label: Text(label),
      );
}

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Panel(
            title: title,
            subtitle: 'Módulo planejado',
            child: const EmptyState(
              icon: Icons.layers_outlined,
              title: 'Próxima etapa',
              description:
                  'Esta área ainda não registra dados. Contas, movimentações, cartões e tarefas já funcionam localmente.',
            ),
          ),
        ),
      );
}

class _Page extends StatelessWidget {
  const _Page({required this.heading, required this.content});

  final Widget heading;
  final Widget content;

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: ListView(
          padding: pagePadding(context),
          children: [heading, const SizedBox(height: 24), content],
        ),
      );
}

Widget _primaryAction(String label, VoidCallback onPressed) =>
    FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label),
    );
