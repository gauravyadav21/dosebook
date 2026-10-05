import '../api/models.dart';
import '../app/format.dart';

/// One local notification to schedule.
class PlannedReminder {
  PlannedReminder({required this.id, required this.at, required this.title, required this.body, required this.followUp});

  /// Stable id, so re-planning replaces instead of duplicating.
  final int id;
  final DateTime at;
  final String title;
  final String body;
  final bool followUp;
}

/// Clock time used for each named slot.
const slotTimes = {'MORNING': (8, 0), 'NOON': (13, 0), 'EVENING': (18, 0), 'NIGHT': (21, 0)};

const followUpDelay = Duration(minutes: 30);

/// Android keeps a limited number of pending alarms per app, so only the nearest ones are scheduled.
/// The plan is rebuilt whenever the app opens or a dose is marked.
const maxPlanned = 60;

/// The clock time of a slot: a named one, or the user's own "HH:mm". Null when it cannot be read.
(int, int)? _timeOf(String slot) {
  final named = slotTimes[slot];
  if (named != null) return named;
  final parts = slot.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return (hour, minute);
}

int _idFor(String medicineId, String date, String slot, bool followUp) =>
    ('$medicineId|$date|$slot|$followUp'.hashCode & 0x3fffffff);

/// Key identifying one dose: used to skip doses already marked taken or skipped.
String doseKey(String medicineId, String date, String slot) => '$medicineId|$date|$slot';

/// Builds the notifications for the coming [days] from confirmed schedules (S6):
/// one at each dose time and one follow-up [followUpDelay] later.
/// Doses in [marked] and times already past are left out; courses stop at their end date.
List<PlannedReminder> planReminders({
  required List<ActiveSchedule> schedules,
  required DateTime now,
  Set<String> marked = const {},
  int days = 3,
}) {
  final planned = <PlannedReminder>[];
  for (var offset = 0; offset < days; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    final date = isoDate(day);
    for (final s in schedules) {
      if (date.compareTo(s.startDate) < 0) continue;
      if (s.endDate != null && date.compareTo(s.endDate!) >= 0) continue;
      for (final slot in s.slots) {
        if (marked.contains(doseKey(s.medicineId, date, slot))) continue;
        final time = _timeOf(slot);
        // One unreadable time must not stop every other reminder from being planned.
        if (time == null) continue;
        final (hour, minute) = time;
        final at = DateTime(day.year, day.month, day.day, hour, minute);
        final own = s.origin == 'YOUR_REMINDER';
        final detail = dotted([s.dose, foodLabel(s.food), own ? 'your reminder' : 'as prescribed']);
        for (final followUp in [false, true]) {
          final when = followUp ? at.add(followUpDelay) : at;
          if (!when.isAfter(now)) continue;
          planned.add(PlannedReminder(
            id: _idFor(s.medicineId, date, slot, followUp),
            at: when,
            title: followUp ? 'Still due: ${s.name}' : 'Time for ${s.name}',
            body: detail,
            followUp: followUp,
          ));
        }
      }
    }
  }
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned.take(maxPlanned).toList();
}
