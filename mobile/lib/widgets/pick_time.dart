import 'package:flutter/material.dart';

/// "HH:mm" as the server stores it.
String hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Opens the system time picker, starting at [initial] ("HH:mm"). Returns the choice as "HH:mm", or null if cancelled.
/// One picker for every place a time is chosen: own reminders, dose times, note reminders.
Future<String?> pickClockTime(BuildContext context, String initial) async {
  final parts = initial.split(':');
  final start = TimeOfDay(hour: int.tryParse(parts.first) ?? 8, minute: int.tryParse(parts.last) ?? 0);
  final picked = await showTimePicker(context: context, initialTime: start);
  return picked == null ? null : hhmm(picked);
}
