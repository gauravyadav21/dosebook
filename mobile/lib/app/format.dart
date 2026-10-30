/// Display helpers shared across screens. Pure functions.
library;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// The device's calendar date as YYYY-MM-DD, the format the backend uses.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "2026-03-12" -> "12 Mar 2026". Returns the input unchanged if it is not a date.
String prettyDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
}

/// "Sunday 4 October".
String longDay(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_monthNames[d.month - 1]}';

/// "08:05" or a DateTime -> "8:05 am".
String clock(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'am' : 'pm'}';
}

String clockFromText(String hhmm) {
  final parts = hhmm.split(':');
  return clock(int.parse(parts[0]), int.parse(parts[1]));
}

const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// A note reminder in words: "Once on 12 Oct 2026 at 9:00 am", "Daily at 9:00 am", "Weekly on Monday at 7:30 am", "Monthly on day 5 at 8:00 am".
String reminderWords(String frequency, String time, {int? weekday, int? dayOfMonth, String? date}) {
  final at = clockFromText(time);
  return switch (frequency) {
    'ONCE' => 'Once on ${date == null ? '?' : prettyDate(date)} at $at',
    'WEEKLY' => 'Weekly on ${weekdayNames[((weekday ?? 1) - 1).clamp(0, 6)]} at $at',
    'MONTHLY' => 'Monthly on day ${dayOfMonth ?? 1} at $at',
    _ => 'Daily at $at',
  };
}

/// The three times of day a medicine is taken at (S14).
const slotOrder = ['MORNING', 'LUNCH', 'DINNER'];

/// The time a named slot means until the user chooses one. Must match the server's `DEFAULT_SLOT_TIMES`.
const defaultSlotTimes = {'MORNING': '08:00', 'LUNCH': '13:00', 'DINNER': '20:00'};

String slotLabel(String slot) => switch (slot) {
      'MORNING' => 'Morning',
      'LUNCH' => 'Lunch',
      'DINNER' => 'Dinner',
      _ => clockFromText(slot),
    };

/// Which part of the day a slot or clock time belongs to. Must match the server's `slotGroupOf`:
/// before 11:00 morning, before 16:00 lunch, otherwise dinner.
String slotGroupOf(String slotOrTime) {
  if (slotOrder.contains(slotOrTime)) return slotOrTime;
  final hour = int.tryParse(slotOrTime.split(':').first) ?? 0;
  if (hour < 11) return 'MORNING';
  if (hour < 16) return 'LUNCH';
  return 'DINNER';
}

String? foodLabel(String? food) => switch (food) {
      'BEFORE_FOOD' => 'before food',
      'AFTER_FOOD' => 'after food',
      _ => null,
    };

String? feedbackLabel(String? feedback) => switch (feedback) {
      'WORKED' => 'Worked',
      'DID_NOT_WORK' => 'Did not work',
      'SIDE_EFFECT' => 'Side effect',
      _ => null,
    };

/// Joins the non-empty parts with a middle dot: "500 mg · 3 times a day".
String dotted(Iterable<String?> parts) => parts.where((p) => p != null && p.trim().isNotEmpty).join(' · ');
