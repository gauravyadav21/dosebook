import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/platform.dart';
import '../../app/wording.dart';
import '../../widgets/common.dart';

/// Doctor's contact as confirmed from the prescription, with Call and Share (S9).
/// Used on the prescription's Doctor tab and on the doctor card.
class DoctorDetails extends StatelessWidget {
  const DoctorDetails({super.key, required this.doctor});

  final Doctor doctor;

  Future<void> _call(BuildContext context) async {
    final ok = await openDialler(doctor.phone!);
    if (!ok && context.mounted) showMessage(context, 'Could not open the phone app.');
  }

  Future<void> _share(BuildContext context) async {
    final api = AppScope.api(context);
    try {
      final text = await api.doctorShareText(doctor.id);
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _ShareSheet(text: text),
      );
    } catch (e) {
      if (context.mounted) showMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(doctor.name, style: text.titleLarge),
        if (doctor.specialty != null) ...[
          const SizedBox(height: 4),
          Text(doctor.specialty!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 8),
        DetailRow(icon: Icons.phone, label: 'Phone', value: doctor.phone ?? 'No number on this prescription'),
        DetailRow(
          icon: Icons.badge,
          label: 'Registration no.',
          value: doctor.registrationNo ?? 'Not on prescription',
        ),
        DetailRow(icon: Icons.schedule, label: 'Availability', value: doctor.availability ?? 'Not on prescription'),
        Text(notVerified, style: muted),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              // Without a number there is nothing to call; the user can add one by editing the card.
              child: FilledButton(
                onPressed: doctor.phone == null ? null : () => _call(context),
                child: const Text('Call'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonal(onPressed: () => _share(context), child: const Text('Share')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(emergencyLine, style: muted),
      ],
    );
  }
}

/// Shows exactly what will be sent before the system share sheet opens.
class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Share doctor's contact", style: theme.titleLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(text, style: theme.bodyMedium),
            ),
            const SizedBox(height: 16),
            const InfoBanner(shareOnlyContact),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await shareText(text);
                  },
                  child: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
