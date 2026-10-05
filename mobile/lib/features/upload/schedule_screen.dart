import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../app/wording.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import 'review_screen.dart';
import 'schedule_editor.dart';

/// Confirm the dose schedule for each medicine. Confirm saves the prescription and sets reminders (S2, S6).
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.reviewed});

  final ReviewedPrescription reviewed;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final List<ScheduleDraft> _drafts = [for (final _ in widget.reviewed.medicines) ScheduleDraft()];
  bool _busy = false;

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Json _body({String? sameDoctorId, bool newDoctor = false}) {
    final r = widget.reviewed;
    final start = isoDate(DateTime.now());
    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return {
      'condition': r.condition,
      'date': r.date,
      'doctor': r.doctor,
      'sameDoctorId': ?sameDoctorId,
      if (newDoctor) 'newDoctor': true,
      'medicines': [
        for (final (i, m) in r.medicines.indexed)
          {
            'name': m.name.text.trim(),
            'dose': m.dose.text.trim(),
            'frequency': ?optional(m.frequency),
            'duration': ?optional(m.duration),
            'schedule': _drafts[i].toJson(startDate: start),
          },
      ],
    };
  }

  Future<void> _confirm() async {
    final session = AppScope.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      try {
        await session.api.confirm(widget.reviewed.documentId, _body());
      } on DoctorNameMatch catch (match) {
        // Only the name matches an existing card: the user decides, nothing is merged silently (S9).
        if (!mounted) return;
        final choice = await showDialog<_DoctorChoice>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SameDoctorDialog(name: widget.reviewed.doctor['name'] as String, candidates: match.candidates),
        );
        if (choice == null) return;
        await session.api.confirm(
          widget.reviewed.documentId,
          _body(sameDoctorId: choice.sameDoctorId, newDoctor: choice.sameDoctorId == null),
        );
      }
      await session.reminders.sync(session.api);
      navigator.popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final medicines = widget.reviewed.medicines;
    final complete = _drafts.every((d) => d.complete);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm schedule')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (i, m) in medicines.indexed) ...[
            if (i > 0) const Divider(height: 32),
            Text(dotted([m.name.text.trim(), m.dose.text.trim()]), style: text.titleMedium),
            const SizedBox(height: 8),
            ScheduleEditor(draft: _drafts[i], onChanged: () => setState(() {})),
            if (!_drafts[i].complete) ...[
              const SizedBox(height: 8),
              Text(
                '${m.name.text.trim()}: ${_drafts[i].missing} to continue.',
                style: text.bodyMedium?.copyWith(color: scheme.error),
              ),
            ],
          ],
          const SizedBox(height: 24),
          const InfoBanner(remindersFollowPrescription),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: complete && !_busy ? _confirm : null,
            child: const Text('Confirm and set reminders'),
          ),
        ],
      ),
    );
  }
}

class _DoctorChoice {
  _DoctorChoice(this.sameDoctorId);

  /// Null means "new doctor".
  final String? sameDoctorId;
}

class _SameDoctorDialog extends StatelessWidget {
  const _SameDoctorDialog({required this.name, required this.candidates});

  final String name;
  final List<Doctor> candidates;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Same doctor?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This prescription names $name. You already have a card with this name. Tap the card if it is the same doctor.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final doctor in candidates)
              DoctorCard(doctor: doctor, onTap: () => Navigator.of(context).pop(_DoctorChoice(doctor.id))),
            const SizedBox(height: 8),
            Text(
              'If you are not sure, choose new doctor. You can edit cards later.',
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop(_DoctorChoice(null)), child: const Text('No, new doctor')),
        if (candidates.length == 1)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_DoctorChoice(candidates.single.id)),
            child: const Text('Yes, same doctor'),
          ),
      ],
    );
  }
}
