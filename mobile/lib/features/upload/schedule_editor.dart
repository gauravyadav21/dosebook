import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/format.dart';

/// The dose schedule for one medicine while the user is filling it in (S2, S6).
class ScheduleDraft {
  ScheduleDraft({Set<String>? slots, this.food, String courseDays = ''})
      : slots = slots ?? {},
        courseDays = TextEditingController(text: courseDays);

  factory ScheduleDraft.from(Schedule s) =>
      ScheduleDraft(slots: s.slots.toSet(), food: s.food, courseDays: '${s.courseDays ?? ''}');

  final Set<String> slots;
  String? food;
  final TextEditingController courseDays;

  static const maxCourseDays = 365;

  int? get days {
    final n = int.tryParse(courseDays.text.trim());
    return (n != null && n >= 1 && n <= maxCourseDays) ? n : null;
  }

  /// Confirm stays disabled until every part is filled.
  bool get complete => slots.isNotEmpty && food != null && days != null;

  /// What is still missing, in plain words; empty when complete.
  String get missing {
    final parts = [
      if (slots.isEmpty) 'choose the times of day',
      if (food == null) 'choose before or after food',
      if (days == null) 'enter the course length (1 to $maxCourseDays days)',
    ];
    return parts.join(', ');
  }

  Json toJson({String? startDate}) => {
        'slots': slotOrder.where(slots.contains).toList(),
        'food': food,
        'dosesPerDay': slots.length,
        'courseDays': days,
        'startDate': ?startDate,
      };

  void dispose() => courseDays.dispose();
}

class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({super.key, required this.draft, required this.onChanged});

  final ScheduleDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final slot in slotOrder)
              FilterChip(
                label: Text(slotLabel(slot)),
                selected: draft.slots.contains(slot),
                onSelected: (on) {
                  on ? draft.slots.add(slot) : draft.slots.remove(slot);
                  onChanged();
                },
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
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Doses per day', border: OutlineInputBorder()),
                child: Text(draft.slots.isEmpty ? '-' : '${draft.slots.length}', style: text.bodyLarge),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: draft.courseDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Course length',
                  suffixText: 'days',
                  border: OutlineInputBorder(),
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
