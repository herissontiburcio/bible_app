import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.local);

  const android = AndroidInitializationSettings('@mipmap/launcher_icon');
  const initSettings = InitializationSettings(android: android);

  await _plugin.initialize(initSettings);

  final androidImpl =
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.requestNotificationsPermission();
}


  Future<void> scheduleDailyVerse({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    // cancelar anterior (para “atualizar” horário/verso)
    await _plugin.cancel(1001);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_verse_channel',
        'Versículo do Dia',
        channelDescription: 'Notificação diária com um versículo',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      1001,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repete todo dia
    );
  }

  Future<void> cancelDailyVerse() => _plugin.cancel(1001);
}
