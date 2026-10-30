import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/format.dart';
import '../../app/tokens.dart';
import '../../widgets/pick_time.dart';

/// The dose schedule for one medicine while the user is filling it in (S2, S6, S14).
class ScheduleDraft {
  ScheduleDraft({
    Set<String>? slots,
    Map<String, String>? customTimes,
    List<String>? extraTimes,
    this.food,
    String courseDays = '',
    String dosesPerDay = '',
  })  : slots = slots ?? {},
        customTimes = customTimes ?? {},
        extraTimes = extraTimes ?? [],
        courseDays = TextEditingController(text: courseDays),
        dosesPerDay = TextEditingController(text: dosesPerDay),
        dosesTouched = dosesPerDay.isNotEmpty;

  /// Reads a saved schedule back. A saved time becomes the chosen time of the morning, lunch or dinner chip for the
  /// part of the day it falls in, if that chip is free; any other time is an extra dose.
  factory ScheduleDraft.from(Schedule s) {
    final slots = {...s.slots};
    final custom = <String, String>{};
    final extra = <String>[];
    for (final t in [...s.times]..sort()) {
      final group = slotGroupOf(t);
      if (slots.contains(group)) {
        extra.add(t);
      } else {
        slots.add(group);
        custom[group] = t;
      }
    }
    return ScheduleDraft(
      slots: slots,
      customTimes: custom,
      extraTimes: extra,
      food: s.food,
      courseDays: '${s.courseDays ?? ''}',
      dosesPerDay: '${s.dosesPerDay}',
    );
  }

  /// The times of day taken (MORNING, LUNCH, DINNER).
  final Set<String> slots;

  /// A time the user chose for a slot. A slot without one is taken at its default time.
  final Map<String, String> customTimes;

  /// Further doses at clock times of the user's own ("HH:mm"), for medicines taken more than three times a day.
  final List<String> extraTimes;
  String? food;
  final TextEditingController courseDays;

  /// How many doses a day. Follows the number of times chosen until the user types their own number.
  final TextEditingController dosesPerDay;
  bool dosesTouched;

  static const maxCourseDays = 365;
  static const maxDosesPerDay = 12;

  int? get days {
    final n = int.tryParse(courseDays.text.trim());
    return (n != null && n >= 1 && n <= maxCourseDays) ? n : null;
  }

  int? get doses {
    final n = int.tryParse(dosesPerDay.text.trim());
    return (n != null && n >= 1 && n <= maxDosesPerDay) ? n : null;
  }

  /// When a slot is taken: the chosen time, or its default.
  String timeOf(String slot) => customTimes[slot] ?? defaultSlotTimes[slot]!;

  bool isCustom(String slot) => customTimes.containsKey(slot);

  /// How many times are chosen: the chips plus the extra times.
  int get count => slots.length + extraTimes.length;

  /// Every chosen clock time, in day order.
  List<String> get allTimes =>
      [for (final s in slotOrder) if (slots.contains(s)) timeOf(s), ...extraTimes]..sort();

  /// Two doses at the same clock time.
  bool get duplicate => allTimes.toSet().length != count;

  /// Until the user types a number of their own, doses per day is simply how many times are chosen.
  void syncDoses() {
    if (!dosesTouched) dosesPerDay.text = count == 0 ? '' : '$count';
  }

  /// Confirm stays disabled until every part is filled and the number of doses matches the times chosen.
  bool get complete => count > 0 && doses == count && !duplicate && food != null && days != null;

  /// What is still missing, in plain words; empty when complete.
  String get missing {
    final n = doses;
    final parts = [
      if (count == 0) 'choose the times of day',
      if (count > 0 && n == null) 'enter doses per day (1 to $maxDosesPerDay)',
      if (count > 0 && n != null && n > count) 'add ${n - count} more ${n - count == 1 ? 'time' : 'times'} to match doses per day',
      if (count > 0 && n != null && n < count) 'remove ${count - n} ${count - n == 1 ? 'time' : 'times'} or raise doses per day',
      if (duplicate) 'two doses are at the same time',
      if (food == null) 'choose before or after food',
      if (days == null) 'enter the course length (1 to $maxCourseDays days)',
    ];
    return parts.join(', ');
  }

  Json toJson({String? startDate}) => {
        'slots': slotOrder.where((s) => slots.contains(s) && !isCustom(s)).toList(),
        'times': [for (final s in slotOrder) if (slots.contains(s) && isCustom(s)) customTimes[s]!, ...extraTimes]..sort(),
        'food': food,
        'dosesPerDay': doses ?? count,
        'courseDays': days,
        'startDate': ?startDate,
      };

  void dispose() {
    courseDays.dispose();
    dosesPerDay.dispose();
  }
}

class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({super.key, required this.draft, required this.onChanged});

  final ScheduleDraft draft;
  final VoidCallback onChanged;

  /// Asks for the time of a chosen slot. Cancelling keeps what it had; choosing the default time again goes back to the default.
  Future<void> _chooseTime(BuildContext context, String slot) async {
    final picked = await pickClockTime(context, draft.timeOf(slot));
    if (picked == null) return;
    if (picked == defaultSlotTimes[slot]) {
      draft.customTimes.remove(slot);
    } else {
      draft.customTimes[slot] = picked;
    }
    onChanged();
  }

  Future<void> _addExtra(BuildContext context) async {
    final picked = await pickClockTime(context, defaultSlotTimes['MORNING']!);
    if (picked == null || draft.allTimes.contains(picked) || draft.allTimes.length >= ScheduleDraft.maxDosesPerDay) return;
    draft.extraTimes
      ..add(picked)
      ..sort();
    draft.syncDoses();
    onChanged();
  }

  Future<void> _changeExtra(BuildContext context, String time) async {
    final picked = await pickClockTime(context, time);
    if (picked == null || picked == time || draft.allTimes.contains(picked)) return;
    draft.extraTimes
      ..remove(time)
      ..add(picked)
      ..sort();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One chip per time of day, showing its time. Selecting one opens the time picker (cancel keeps the default);
        // the pencil on a chosen chip opens it again. Doses beyond the three come from "Add a time".
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final slot in slotOrder)
              InputChip(
                label: Text('${slotLabel(slot)} ${clockFromText(draft.timeOf(slot))}'),
                selected: draft.slots.contains(slot),
                onSelected: (on) async {
                  if (on) {
                    draft.slots.add(slot);
                  } else {
                    draft.slots.remove(slot);
                    draft.customTimes.remove(slot);
                  }
                  draft.syncDoses();
                  onChanged();
                  if (on) await _chooseTime(context, slot);
                },
                onDeleted: draft.slots.contains(slot) ? () => _chooseTime(context, slot) : null,
                deleteIcon: const Icon(Icons.edit_outlined),
                deleteButtonTooltipMessage: 'Change the ${slotLabel(slot).toLowerCase()} time',
              ),
            for (final time in draft.extraTimes)
              InputChip(
                label: Text(clockFromText(time)),
                onPressed: () => _changeExtra(context, time),
                onDeleted: () {
                  draft.extraTimes.remove(time);
                  draft.syncDoses();
                  onChanged();
                },
                deleteButtonTooltipMessage: 'Remove ${clockFromText(time)}',
              ),
            ActionChip(
              avatar: const Icon(Icons.add),
              label: const Text('Add a time'),
              onPressed: () => _addExtra(context),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final food in const ['BEFORE_FOOD', 'AFTER_FOOD'])
              FilterChip(
                label: Text(food == 'BEFORE_FOOD' ? 'Before food' : 'After food'),
                selected: draft.food == food,
                onSelected: (on) {
                  draft.food = on ? food : null;
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: draft.dosesPerDay,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Doses per day',
                  helperText: draft.count == 0 ? '1 to ${ScheduleDraft.maxDosesPerDay}' : '${draft.count} ${draft.count == 1 ? 'time' : 'times'} chosen',
                ),
                onChanged: (_) {
                  draft.dosesTouched = draft.dosesPerDay.text.trim().isNotEmpty;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: draft.courseDays,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Course length',
                  suffixText: 'days',
                  helperText: '1 to ${ScheduleDraft.maxCourseDays} days',
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
