import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../api/api.dart';
import '../app/format.dart';
import 'reminder_plan.dart';

/// Dose reminders on the phone. Built only from schedules the user confirmed (S6) or set themselves (S7).
abstract class Reminders {
  /// Re-reads schedules and today's marks from the server and replaces all pending notifications.
  Future<void> sync(Api api);

  Future<void> clear();
}

/// Used in tests and on platforms without local notifications.
class NoReminders implements Reminders {
  @override
  Future<void> sync(Api api) async {}

  @override
  Future<void> clear() async {}
}

class LocalReminders implements Reminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'doses',
      'Dose reminders',
      channelDescription: 'Reminders for doses from your confirmed prescriptions and your own reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  @override
  Future<void> sync(Api api) async {
    try {
      await _init();
      final now = DateTime.now();
      final today = isoDate(now);
      final schedules = await api.schedules(today);
      final doses = await api.today(today);
      final marked = {
        for (final d in doses)
          if (d.status != 'DUE') doseKey(d.medicineId, today, d.slot),
      };
      await _plugin.cancelAll();
      for (final r in planReminders(schedules: schedules, now: now, marked: marked)) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          // An absolute instant; no device time-zone lookup is needed.
          scheduledDate: tz.TZDateTime.from(r.at.toUtc(), tz.UTC),
          notificationDetails: _details,
          // Inexact alarms need no special permission; a reminder may arrive a few minutes late.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      // Reminders are best effort: the Today list always shows what is due.
      debugPrint('Reminder sync failed: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _init();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Reminder clear failed: $e');
    }
  }
}
