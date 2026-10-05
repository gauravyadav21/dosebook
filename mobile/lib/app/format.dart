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

const slotOrder = ['MORNING', 'NOON', 'EVENING', 'NIGHT'];

String slotLabel(String slot) => switch (slot) {
      'MORNING' => 'Morning',
      'NOON' => 'Noon',
      'EVENING' => 'Evening',
      'NIGHT' => 'Night',
      _ => clockFromText(slot),
    };

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
