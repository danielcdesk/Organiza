import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_schedule.dart';

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
        settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      windows: WindowsInitializationSettings(
          appName: 'Organiza',
          appUserModelId: 'com.danielcdesk.organiza',
          guid: 'a18b8b7a-35b1-4bb2-9c14-9a0e3aa36ac1'),
    ));
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  Future<void> reschedule(List<LocalReminder> reminders) async {
    await initialize();
    await _plugin.cancelAll();
    for (final reminder in reminders) {
      if (reminder.date.isBefore(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        id: reminder.id.hashCode & 0x7fffffff,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.date, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
              'organiza_reminders', 'Lembretes financeiros',
              channelDescription:
                  'Pendências, faturas e assinaturas do Organiza',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority),
          windows: WindowsNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}
