import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A daily reminder the user can switch on/off from Settings.
class Reminder {
  final int id;
  final String key;
  final String label;
  final String title;
  final String body;
  final int hour;
  final int minute;
  const Reminder(this.id, this.key, this.label, this.title, this.body, this.hour, this.minute);
}

const reminders = [
  Reminder(1, 'breakfast', 'Breakfast', 'Good morning! 🌅', "Log your breakfast to start the day strong.", 8, 0),
  Reminder(2, 'lunch', 'Lunch', 'Lunch time 🍱', "Don't forget to log your lunch.", 12, 30),
  Reminder(3, 'dinner', 'Dinner', 'Dinner time 🍽️', 'Log your dinner while it is fresh in your mind.', 19, 0),
  Reminder(4, 'water', 'Hydration', 'Stay hydrated 💧', 'Time for a glass of water.', 15, 0),
  Reminder(5, 'checkin', 'Evening check-in', 'Complete your diary ✅', 'Finish logging today to keep your streak alive.', 21, 0),
];

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC; reminders will still fire, possibly offset.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  Future<Map<String, bool>> enabledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return {for (final r in reminders) r.key: prefs.getBool('reminder_${r.key}') ?? false};
  }

  Future<bool> setReminder(Reminder r, bool enabled) async {
    await init();
    if (enabled && !await requestPermission()) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_${r.key}', enabled);
    if (enabled) {
      await _schedule(r);
    } else {
      await _plugin.cancel(id: r.id);
    }
    return true;
  }

  /// Re-schedules enabled reminders (call on app start).
  Future<void> restore() async {
    final enabled = await enabledReminders();
    if (!enabled.containsValue(true)) return;
    await init();
    for (final r in reminders) {
      if (enabled[r.key] == true) await _schedule(r);
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    for (final r in reminders) {
      await prefs.remove('reminder_${r.key}');
    }
  }

  Future<void> _schedule(Reminder r) async {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, r.hour, r.minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: r.id,
      title: r.title,
      body: r.body,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          channelDescription: 'Meal, water and diary reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
