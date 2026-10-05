import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../app/wording.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../doctors/doctor_details.dart';
import '../doctors/doctors_screen.dart';
import '../upload/schedule_editor.dart';

/// One confirmed prescription: its medicines, and the doctor who wrote it (S3, S9).
class PrescriptionScreen extends StatelessWidget {
  const PrescriptionScreen({super.key, required this.prescriptionId});

  final String prescriptionId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prescription'),
          bottom: const TabBar(tabs: [Tab(text: 'Medicines'), Tab(text: 'Doctor')]),
        ),
        body: Loader<Prescription>(
          load: () => AppScope.api(context).prescription(prescriptionId),
          builder: (context, p, reload) => TabBarView(
            children: [
              _MedicinesTab(prescription: p),
              _DoctorTab(prescription: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicinesTab extends StatelessWidget {
  const _MedicinesTab({required this.prescription});

  final Prescription prescription;

  bool _active(Medicine m) {
    final s = m.schedule;
    if (s == null || s.stopped) return false;
    return s.endDate == null || isoDate(DateTime.now()).compareTo(s.endDate!) < 0;
  }

  Future<void> _stop(BuildContext context, Medicine m) async {
    final session = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stop reminders for ${m.name}?'),
        content: const Text(
          'No more doses will be listed or reminded from today. Doses you already marked are kept. '
          'Ask your doctor before stopping a prescribed course.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Stop reminders')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await guarded(context, () => session.api.stopCourse(m.id, isoDate(DateTime.now())));
    if (ok) await session.reminders.sync(session.api);
  }

  Future<void> _edit(BuildContext context, Medicine m) async {
    final session = AppScope.of(context);
    final changed = await Navigator.of(context)
        .push(MaterialPageRoute<bool>(builder: (_) => EditCourseScreen(medicine: m)));
    if (changed == true) await session.reminders.sync(session.api);
  }

  Future<void> _viewOriginal(BuildContext context) async {
    final api = AppScope.api(context);
    try {
      final file = await api.documentFile(prescription.documentId);
      if (!context.mounted) return;
      if (!file.contentType.startsWith('image/')) {
        showMessage(context, 'This prescription is a PDF. PDF preview is not available in the app yet.');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(file.bytes))),
      );
    } catch (e) {
      if (context.mounted) showMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final p = prescription;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(prettyDate(p.date), style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            const SourceTag(selfAdded: false),
          ],
        ),
        const SizedBox(height: 12),
        Text(p.condition, style: text.titleLarge),
        const SizedBox(height: 12),
        for (final m in p.medicines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MedicineCard(
              name: m.name,
              selfAdded: false,
              dose: dotted([m.dose, m.frequency, m.duration]),
              meta: m.schedule == null
                  ? null
                  : dotted([
                      m.schedule!.slots.map(slotLabel).join(', '),
                      foodLabel(m.schedule!.food),
                      m.schedule!.stopped ? 'reminders stopped' : '${m.schedule!.courseDays} days',
                    ]),
              footer: 'Did it work for you?',
              // Feedback is given here, on the prescription, at any time. Chat only shows it.
              feedback: m.feedback,
              onFeedback: (value) => guarded(context, () => AppScope.api(context).setFeedback(m.id, value)),
              actions: _active(m)
                  ? [
                      TextButton(onPressed: () => _edit(context, m), child: const Text('Edit schedule')),
                      TextButton(onPressed: () => _stop(context, m), child: const Text('Stop reminders')),
                    ]
                  : const [],
            ),
          ),
        Text(
          'Doses taken: ${p.taken} of ${p.total}',
          style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: () => _viewOriginal(context), child: const Text('View original document')),
        ),
      ],
    );
  }
}

class _DoctorTab extends StatelessWidget {
  const _DoctorTab({required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    final doctor = prescription.doctor;
    if (doctor == null) {
      return const EmptyState(
        icon: Icons.contacts,
        title: 'No doctor card',
        body: 'The contact card for this prescription was deleted. The prescription itself is kept.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DoctorDetails(doctor: doctor),
        const Divider(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DoctorPrescriptionsScreen(doctorId: doctor.id, doctorName: doctor.name),
              ),
            ),
            child: const Text('All prescriptions from this doctor'),
          ),
        ),
      ],
    );
  }
}

/// Change the times, food timing or length of a prescribed course. Pops `true` when saved (S6).
class EditCourseScreen extends StatefulWidget {
  const EditCourseScreen({super.key, required this.medicine});

  final Medicine medicine;

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  late final ScheduleDraft _draft = ScheduleDraft.from(widget.medicine.schedule!);
  bool _busy = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final api = AppScope.api(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final ok = await guarded(context, () => api.editSchedule(widget.medicine.id, _draft.toJson()));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final m = widget.medicine;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit schedule')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(dotted([m.name, m.dose]), style: text.titleMedium),
          const SizedBox(height: 8),
          ScheduleEditor(draft: _draft, onChanged: () => setState(() {})),
          if (!_draft.complete) ...[
            const SizedBox(height: 8),
            Text('${m.name}: ${_draft.missing} to continue.', style: text.bodyMedium?.copyWith(color: scheme.error)),
          ],
          const SizedBox(height: 24),
          const InfoBanner(remindersFollowPrescription),
          const SizedBox(height: 12),
          FilledButton(onPressed: _draft.complete && !_busy ? _save : null, child: const Text('Save schedule')),
        ],
      ),
    );
  }
}
