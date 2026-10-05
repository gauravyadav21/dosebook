import 'package:flutter/material.dart';

import '../api/models.dart';
import '../app/format.dart';
import 'common.dart';

/// Worked / Did not work / Side effect. Tapping the selected chip clears the feedback.
class FeedbackChips extends StatelessWidget {
  const FeedbackChips({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _options = ['WORKED', 'DID_NOT_WORK', 'SIDE_EFFECT'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final option in _options)
          FilterChip(
            label: Text(feedbackLabel(option)!),
            selected: value == option,
            onSelected: (selected) => onChanged(selected ? option : null),
          ),
      ],
    );
  }
}

/// A medicine from the user's own history. Always shows where it came from.
class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.name,
    required this.selfAdded,
    this.dose,
    this.meta,
    this.footer,
    this.feedback,
    this.onFeedback,
    this.onTap,
    this.actions = const [],
  });

  final String name;
  final bool selfAdded;
  final String? dose;
  final String? meta;
  final String? footer;
  final String? feedback;

  /// When set, feedback chips are shown.
  final ValueChanged<String?>? onFeedback;
  final VoidCallback? onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: text.titleMedium)),
                  const SizedBox(width: 8),
                  SourceTag(selfAdded: selfAdded),
                ],
              ),
              if (dose != null && dose!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(dose!, style: text.bodyMedium),
              ],
              if (meta != null && meta!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(meta!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              if (footer != null && footer!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(footer!, style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              if (onFeedback != null) ...[
                const SizedBox(height: 8),
                FeedbackChips(value: feedback, onChanged: onFeedback!),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 4),
                // Wraps onto a second line on narrow phones instead of overflowing.
                Align(alignment: Alignment.centerRight, child: Wrap(alignment: WrapAlignment.end, children: actions)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One confirmed prescription on the timeline.
class TimelineEntry extends StatelessWidget {
  const TimelineEntry({super.key, required this.prescription, this.onTap});

  final Prescription prescription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final p = prescription;
    return Card.outlined(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(prettyDate(p.date), style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  const SourceTag(selfAdded: false),
                ],
              ),
              const SizedBox(height: 8),
              Text(p.condition, style: text.titleMedium),
              const SizedBox(height: 8),
              for (final m in p.medicines) Text(dotted([m.name, m.dose, m.frequency, m.duration]), style: text.bodyMedium),
              if (p.doctor != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Prescribed by ${p.doctor!.name}',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Doses taken: ${p.taken} of ${p.total}',
                style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One dose in Today, with Taken / Skipped.
class DoseRow extends StatelessWidget {
  const DoseRow({super.key, required this.dose, required this.onMark, this.onEdit});

  final Dose dose;
  final ValueChanged<String> onMark;

  /// Set for the user's own reminders, which can be edited from Today.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    final taken = dose.status == 'TAKEN';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(dose.name, style: text.titleMedium)),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit my reminder for ${dose.name}',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dotted([dose.dose, foodLabel(dose.food), dose.isOwnReminder ? '(your own words)' : null]),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(dose.isOwnReminder ? 'Your reminder · Self-added' : 'As prescribed', style: muted),
            const SizedBox(height: 4),
            if (dose.status == 'DUE')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => onMark('SKIPPED'), child: const Text('Skipped')),
                  const SizedBox(width: 8),
                  FilledButton.tonal(onPressed: () => onMark('TAKEN'), child: const Text('Taken')),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    taken ? Icons.check : Icons.close,
                    size: 18,
                    color: taken ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      taken
                          ? 'Taken${dose.markedAt == null ? '' : ' at ${clock(dose.markedAt!.hour, dose.markedAt!.minute)}'}'
                          : 'Skipped',
                      style: text.labelLarge?.copyWith(color: taken ? scheme.primary : scheme.onSurfaceVariant),
                    ),
                  ),
                  // A mark can be corrected (S6).
                  TextButton(
                    onPressed: () => onMark(taken ? 'SKIPPED' : 'TAKEN'),
                    child: Text(taken ? 'Mark skipped' : 'Mark taken'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact doctor contact card for the Doctors list.
class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.onTap});

  final Doctor doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    final count = doctor.prescriptionCount;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doctor.name, style: text.titleMedium),
              if (doctor.specialty != null) ...[
                const SizedBox(height: 4),
                Text(doctor.specialty!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(doctor.phone ?? 'No number on this prescription. Tap to add.', style: text.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                doctor.registrationNo == null ? 'Reg. no. not on prescription' : 'Reg. no. ${doctor.registrationNo}',
                style: muted,
              ),
              const SizedBox(height: 4),
              Text(count == 1 ? '1 prescription' : '$count prescriptions', style: muted),
            ],
          ),
        ),
      ),
    );
  }
}
