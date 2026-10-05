import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/format.dart';
import '../../app/wording.dart';
import '../../widgets/common.dart';
import 'schedule_screen.dart';

class MedicineDraft {
  MedicineDraft({String name = '', String dose = '', String frequency = '', String duration = ''})
      : name = TextEditingController(text: name),
        dose = TextEditingController(text: dose),
        frequency = TextEditingController(text: frequency),
        duration = TextEditingController(text: duration);

  final TextEditingController name;
  final TextEditingController dose;
  final TextEditingController frequency;
  final TextEditingController duration;

  bool get complete => name.text.trim().isNotEmpty && dose.text.trim().isNotEmpty;

  void dispose() {
    name.dispose();
    dose.dispose();
    frequency.dispose();
    duration.dispose();
  }
}

/// Everything the user reviewed on this screen, passed on to the schedule step.
class ReviewedPrescription {
  ReviewedPrescription({
    required this.documentId,
    required this.condition,
    required this.date,
    required this.doctor,
    required this.medicines,
  });

  final String documentId;
  final String condition;
  final String date;
  final Json doctor;
  final List<MedicineDraft> medicines;
}

/// Review what was read, or type it in when reading failed. Nothing is saved here (S2, S8, S9).
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.document});

  final UploadedDocument document;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final TextEditingController _condition;
  late final TextEditingController _doctorName;
  late final TextEditingController _phone;
  late final TextEditingController _registration;
  late final TextEditingController _specialty;
  late final TextEditingController _availability;
  late final List<MedicineDraft> _medicines;
  String? _date;

  static final _phonePattern = RegExp(r'^\+?[0-9][0-9 ()-]{5,19}$');

  @override
  void initState() {
    super.initState();
    final e = widget.document.extraction;
    final doctor = e?.doctor ?? const <String, dynamic>{};
    _condition = TextEditingController(text: e?.condition ?? '');
    _doctorName = TextEditingController(text: doctor['name'] as String? ?? '');
    _phone = TextEditingController(text: doctor['phone'] as String? ?? '');
    _registration = TextEditingController(text: doctor['registrationNo'] as String? ?? '');
    _specialty = TextEditingController(text: doctor['specialty'] as String? ?? '');
    _availability = TextEditingController(text: doctor['availability'] as String? ?? '');
    _date = e?.date;
    _medicines = [
      for (final m in e?.medicines ?? const <ExtractedMedicine>[])
        MedicineDraft(name: m.name, dose: m.dose ?? '', frequency: m.frequency ?? '', duration: m.duration ?? ''),
    ];
    if (_medicines.isEmpty) _medicines.add(MedicineDraft());
  }

  @override
  void dispose() {
    for (final c in [_condition, _doctorName, _phone, _registration, _specialty, _availability]) {
      c.dispose();
    }
    for (final m in _medicines) {
      m.dispose();
    }
    super.dispose();
  }

  bool get _phoneValid => _phone.text.trim().isEmpty || _phonePattern.hasMatch(_phone.text.trim());

  bool get _complete =>
      _condition.text.trim().isNotEmpty &&
      _date != null &&
      _doctorName.text.trim().isNotEmpty &&
      _phoneValid &&
      _medicines.every((m) => m.complete);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date ?? '') ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      helpText: 'Date on the prescription',
    );
    if (picked != null) setState(() => _date = isoDate(picked));
  }

  void _next() {
    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final reviewed = ReviewedPrescription(
      documentId: widget.document.id,
      condition: _condition.text.trim(),
      date: _date!,
      doctor: {
        'name': _doctorName.text.trim(),
        'phone': ?optional(_phone),
        'registrationNo': ?optional(_registration),
        'specialty': ?optional(_specialty),
        'availability': ?optional(_availability),
      },
      medicines: _medicines,
    );
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ScheduleScreen(reviewed: reviewed)));
  }

  Widget _field(TextEditingController controller, String label, {String? error, TextInputType? keyboard}) => TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, errorText: error, border: const OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final failed = widget.document.extractionFailed;
    const gap = SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(title: Text(failed ? 'Enter details' : 'Check what we read')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoBanner(failed ? couldNotRead : checkAgainstPaper),
          gap,
          _field(_condition, 'Condition'),
          gap,
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                    child: Text(_date == null ? 'Choose' : prettyDate(_date!), style: text.bodyLarge),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _field(_doctorName, 'Prescriber')),
            ],
          ),
          gap,
          Row(
            children: [
              Expanded(
                child: _field(
                  _phone,
                  "Doctor's phone",
                  keyboard: TextInputType.phone,
                  error: _phoneValid ? null : 'Check the number',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _field(_registration, 'Registration no.')),
            ],
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field(_specialty, 'Specialty')),
              const SizedBox(width: 12),
              Expanded(child: _field(_availability, 'Availability')),
            ],
          ),
          gap,
          Text('Medicines', style: text.titleMedium),
          for (final (i, m) in _medicines.indexed) ...[
            gap,
            Row(
              children: [
                Expanded(child: _field(m.name, 'Medicine ${i + 1}')),
                if (_medicines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove medicine',
                    onPressed: () => setState(() => _medicines.removeAt(i).dispose()),
                  ),
              ],
            ),
            gap,
            _field(m.dose, 'Dose'),
            gap,
            Row(
              children: [
                Expanded(child: _field(m.frequency, 'Frequency')),
                const SizedBox(width: 12),
                Expanded(child: _field(m.duration, 'Duration')),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _medicines.add(MedicineDraft())),
              child: const Text('Add another medicine'),
            ),
          ),
          gap,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Leaving here saves nothing: the upload never reaches the timeline without Confirm.
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Discard')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _complete ? _next : null, child: const Text('Next: schedule')),
            ],
          ),
        ],
      ),
    );
  }
}
