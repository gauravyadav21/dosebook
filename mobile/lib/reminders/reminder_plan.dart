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

const followUpDelay = Duration(minutes: 30);

/// Android keeps a limited number of pending alarms per app, so only the nearest ones are scheduled.
/// The plan is rebuilt whenever the app opens or a dose is marked.
const maxPlanned = 60;

/// The clock time of a slot: a named one, or the user's own "HH:mm". Null when it cannot be read.
(int, int)? _timeOf(String slot) {
  final parts = (defaultSlotTimes[slot] ?? slot).split(':');
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

/// How often a note reminder repeats once the phone has scheduled it.
enum NoteRepeat { once, daily, weekly, monthly }

/// One repeating notification for a note (S15). The phone repeats it on its own from [firstAt].
class PlannedNoteReminder {
  PlannedNoteReminder({required this.id, required this.firstAt, required this.title, required this.body, required this.repeat});

  final int id;
  final DateTime firstAt;
  final String title;
  final String body;
  final NoteRepeat repeat;
}

/// Longest text shown under the title; the first line of the note, cut with an ellipsis.
const noteReminderBodyLength = 80;

String _firstLine(String text) {
  final line = text.split('\n').map((l) => l.trim()).firstWhere((l) => l.isNotEmpty, orElse: () => '');
  return line.length <= noteReminderBodyLength ? line : '${line.substring(0, noteReminderBodyLength - 1).trimRight()}…';
}

/// The next time a note reminder fires, strictly after [now].
DateTime? _nextFiring(NoteReminder r, DateTime now) {
  final time = _timeOf(r.time);
  if (time == null) return null;
  final (hour, minute) = time;
  DateTime at(int year, int month, int day) => DateTime(year, month, day, hour, minute);
  switch (r.frequency) {
    case 'ONCE':
      final date = DateTime.tryParse(r.date ?? '');
      if (date == null) return null;
      final at = DateTime(date.year, date.month, date.day, hour, minute);
      return at.isAfter(now) ? at : null;
    case 'DAILY':
      final today = at(now.year, now.month, now.day);
      return today.isAfter(now) ? today : at(now.year, now.month, now.day + 1);
    case 'WEEKLY':
      final weekday = r.weekday;
      if (weekday == null || weekday < 1 || weekday > 7) return null;
      final ahead = (weekday - now.weekday) % 7;
      final candidate = at(now.year, now.month, now.day + ahead);
      return candidate.isAfter(now) ? candidate : at(now.year, now.month, now.day + ahead + 7);
    case 'MONTHLY':
      final day = r.dayOfMonth;
      if (day == null || day < 1 || day > 28) return null;
      final thisMonth = at(now.year, now.month, day);
      return thisMonth.isAfter(now) ? thisMonth : at(now.year, now.month + 1, day);
    default:
      return null;
  }
}

/// The repeating notifications for notes that have a reminder (S15). A note that cannot be read is left out,
/// so one bad row does not stop the others.
List<PlannedNoteReminder> planNoteReminders(List<Note> notes, DateTime now) {
  final planned = <PlannedNoteReminder>[];
  for (final note in notes) {
    final r = note.reminder;
    if (r == null) continue;
    final first = _nextFiring(r, now);
    if (first == null) continue;
    planned.add(PlannedNoteReminder(
      id: 'note|${note.id}'.hashCode & 0x3fffffff,
      firstAt: first,
      title: 'Note reminder',
      body: _firstLine(note.text),
      repeat: switch (r.frequency) {
        'ONCE' => NoteRepeat.once,
        'WEEKLY' => NoteRepeat.weekly,
        'MONTHLY' => NoteRepeat.monthly,
        _ => NoteRepeat.daily,
      },
    ));
  }
  return planned;
}
