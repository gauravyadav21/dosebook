import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/format.dart';
import '../../app/tokens.dart';
import '../../widgets/pick_time.dart';

/// A note reminder in plain words: "Weekly on Monday at 7:30 am".
String noteReminderWords(NoteReminder r) =>
    reminderWords(r.frequency, r.time, weekday: r.weekday, dayOfMonth: r.dayOfMonth, date: r.date);

/// What the reminder sheet gave back. A closed sheet gives nothing (null); [reminder] null means "remove it".
typedef ReminderChoice = ({NoteReminder? reminder});

/// Opens the "Remind me" sheet (S15): once, daily, weekly or monthly, and when. [current] is what the note has now.
Future<ReminderChoice?> showReminderSheet(BuildContext context, {NoteReminder? current, DateTime? now}) {
  return showModalBottomSheet<ReminderChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReminderSheet(current: current, now: now ?? DateTime.now()),
  );
}

class ReminderSheet extends StatefulWidget {
  const ReminderSheet({super.key, this.current, required this.now});

  final NoteReminder? current;
  final DateTime now;

  /// What the user gets when they choose no time.
  static const defaultTime = '09:00';

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  late String _frequency = widget.current?.frequency ?? 'DAILY';
  late String _time = widget.current?.time ?? ReminderSheet.defaultTime;
  late int _weekday = widget.current?.weekday ?? 1;
  late int _day = widget.current?.dayOfMonth ?? 1;
  late String _date = widget.current?.date ?? isoDate(widget.now.add(const Duration(days: 1)));

  NoteReminder get _reminder => NoteReminder(
        frequency: _frequency,
        time: _time,
        weekday: _frequency == 'WEEKLY' ? _weekday : null,
        dayOfMonth: _frequency == 'MONTHLY' ? _day : null,
        date: _frequency == 'ONCE' ? _date : null,
      );

  /// A one-time reminder has to be ahead of now; the others always are.
  bool get _inThePast {
    if (_frequency != 'ONCE') return false;
    final date = DateTime.tryParse(_date);
    if (date == null) return true;
    final parts = _time.split(':');
    final at = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
    return !at.isAfter(widget.now);
  }

  Future<void> _pickTime() async {
    final picked = await pickClockTime(context, _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _pickDate() async {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final initial = DateTime.tryParse(_date) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (picked != null && mounted) setState(() => _date = isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: Space.md, right: Space.md, bottom: Space.md + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: scheme.tertiary),
                Gap.sm,
                Text('Remind me', style: text.titleLarge),
              ],
            ),
            Gap.md,
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ONCE', label: Text('Once')),
                ButtonSegment(value: 'DAILY', label: Text('Daily')),
                ButtonSegment(value: 'WEEKLY', label: Text('Weekly')),
                ButtonSegment(value: 'MONTHLY', label: Text('Monthly')),
              ],
              selected: {_frequency},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _frequency = v.first),
            ),
            if (_frequency == 'ONCE') ...[
              Gap.md,
              ActionChip(
                avatar: const Icon(Icons.event),
                label: Text(prettyDate(_date)),
                tooltip: 'Choose the date',
                onPressed: _pickDate,
              ),
            ],
            if (_frequency == 'WEEKLY') ...[
              Gap.md,
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (var i = 1; i <= 7; i++)
                    ChoiceChip(
                      label: Text(weekdayNames[i - 1].substring(0, 3)),
                      tooltip: weekdayNames[i - 1],
                      selected: _weekday == i,
                      onSelected: (_) => setState(() => _weekday = i),
                    ),
                ],
              ),
            ],
            if (_frequency == 'MONTHLY') ...[
              Gap.md,
              DropdownMenu<int>(
                label: const Text('Day of the month'),
                initialSelection: _day,
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (var d = 1; d <= 28; d++) DropdownMenuEntry(value: d, label: '$d'),
                ],
                onSelected: (v) {
                  if (v != null) setState(() => _day = v);
                },
              ),
            ],
            Gap.md,
            ActionChip(
              avatar: const Icon(Icons.schedule),
              label: Text('At ${clockFromText(_time)}'),
              tooltip: 'Choose the time',
              onPressed: _pickTime,
            ),
            Gap.md,
            Text(
              noteReminderWords(_reminder),
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (_inThePast) ...[
              Gap.xs,
              Text('Choose a date and time that has not passed yet.', style: text.bodyMedium?.copyWith(color: scheme.error)),
            ],
            Gap.lg,
            FilledButton(
              onPressed: _inThePast ? null : () => Navigator.of(context).pop<ReminderChoice>((reminder: _reminder)),
              child: const Text('Set reminder'),
            ),
            if (widget.current != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop<ReminderChoice>((reminder: null)),
                child: const Text('Remove reminder'),
              ),
          ],
        ),
      ),
    );
  }
}
