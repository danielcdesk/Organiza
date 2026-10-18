import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/app_route.dart';
import 'package:organiza/presentation/basic_pages.dart';

void main() {
  testWidgets('shows local reminder and app-lock preferences', (tester) async {
    var reminders = false;
    var lock = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SettingsPage(
          onThemeChanged: (_) {},
          quickPages: const [
            AppRoute.overview,
            AppRoute.finances,
            AppRoute.organization,
            AppRoute.reports
          ],
          onQuickPagesChanged: (_) {},
          profileName: '',
          profileIncomeInCents: 0,
          onEditProfile: () {},
          onExportBackup: () async {},
          onRestoreBackup: () async {},
          remindersEnabled: false,
          reminderDaysAhead: 1,
          reminderHour: 9,
          reminderMinute: 0,
          onRemindersChanged: (value) async {
            reminders = value;
          },
          onReminderPreferencesChanged: ({daysAhead, hour, minute}) async {},
          appLockEnabled: false,
          appLockTimeoutMinutes: 5,
          lockOnWindowHide: false,
          onAppLockPreferencesChanged: (
              {required enabled, timeoutMinutes, onWindowHide}) {
            lock = enabled;
          },
        ),
      ),
    ));
    expect(find.text('Lembretes locais'), findsOneWidget);
    expect(find.text('Bloqueio do aplicativo'), findsOneWidget);
    final reminderToggle = tester.widget<SwitchListTile>(find.ancestor(
      of: find.text('Ativar notificações'),
      matching: find.byType(SwitchListTile),
    ));
    reminderToggle.onChanged!(true);
    await tester.pump();
    expect(reminders, isTrue);
    final lockToggle = tester.widget<SwitchListTile>(find.ancestor(
      of: find.text('Bloquear o Organiza'),
      matching: find.byType(SwitchListTile),
    ));
    lockToggle.onChanged!(true);
    await tester.pump();
    expect(lock, isTrue);
  });
}
