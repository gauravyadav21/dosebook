import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../timeline/prescription_screen.dart';
import 'doctor_details.dart';

/// One contact card per doctor, built from confirmed prescriptions (S9).
class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Doctors')),
      body: Loader<List<Doctor>>(
        load: AppScope.api(context).doctors,
        builder: (context, doctors, reload) {
          if (doctors.isEmpty) {
            return const ScrollableFill(
              child: EmptyState(
                icon: Icons.contacts,
                title: 'No doctors yet',
                body: 'A contact card is created for the doctor on each prescription you confirm.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Created from the prescriptions you confirmed. Details are as printed, not verified by the app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              for (final doctor in doctors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DoctorCard(
                    doctor: doctor,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => DoctorScreen(doctorId: doctor.id))),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A doctor's card with every prescription recorded against them, newest first.
class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  Doctor? _doctor;

  Future<void> _edit() async {
    final doctor = _doctor;
    if (doctor == null) return;
    final deleted =
        await Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => DoctorEditScreen(doctor: doctor)));
    // After an edit the card reloads by itself; after a delete there is nothing left to show.
    if (mounted && deleted == true) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final api = AppScope.api(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor'),
        actions: [IconButton(icon: const Icon(Icons.edit), tooltip: 'Edit doctor', onPressed: _edit)],
      ),
      body: Loader<Doctor>(
        load: () async => _doctor = await api.doctor(widget.doctorId),
        builder: (context, doctor, reload) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DoctorDetails(doctor: doctor),
            const SizedBox(height: 16),
            Text('Prescriptions from this doctor', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in doctor.prescriptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TimelineEntry(
                  prescription: p,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => PrescriptionScreen(prescriptionId: p.id))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Destination of "All prescriptions from this doctor" on a prescription's Doctor tab.
class DoctorPrescriptionsScreen extends StatelessWidget {
  const DoctorPrescriptionsScreen({super.key, required this.doctorId, required this.doctorName});

  final String doctorId;
  final String doctorName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(doctorName)),
      body: Loader<Doctor>(
        load: () => AppScope.api(context).doctor(doctorId),
        builder: (context, doctor, reload) {
          final count = doctor.prescriptions.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${count == 1 ? '1 prescription' : '$count prescriptions'}, newest first',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              for (final p in doctor.prescriptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TimelineEntry(
                    prescription: p,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => PrescriptionScreen(prescriptionId: p.id))),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Edit a doctor card, including adding a missing number. Pops `true` when the card was deleted.
class DoctorEditScreen extends StatefulWidget {
  const DoctorEditScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<DoctorEditScreen> createState() => _DoctorEditScreenState();
}

class _DoctorEditScreenState extends State<DoctorEditScreen> {
  late final _name = TextEditingController(text: widget.doctor.name);
  late final _specialty = TextEditingController(text: widget.doctor.specialty ?? '');
  late final _phone = TextEditingController(text: widget.doctor.phone ?? '');
  late final _registration = TextEditingController(text: widget.doctor.registrationNo ?? '');
  late final _availability = TextEditingController(text: widget.doctor.availability ?? '');
  bool _busy = false;

  static final _phonePattern = RegExp(r'^\+?[0-9][0-9 ()-]{5,19}$');

  @override
  void dispose() {
    for (final c in [_name, _specialty, _phone, _registration, _availability]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _phoneValid => _phone.text.trim().isEmpty || _phonePattern.hasMatch(_phone.text.trim());

  bool get _valid => _name.text.trim().isNotEmpty && _phoneValid;

  Future<void> _save() async {
    final api = AppScope.api(context);
    final navigator = Navigator.of(context);
    // An emptied optional field is sent as null, which clears it.
    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => api.updateDoctor(widget.doctor.id, {
        'name': _name.text.trim(),
        'specialty': optional(_specialty),
        'phone': optional(_phone),
        'registrationNo': optional(_registration),
        'availability': optional(_availability),
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) navigator.pop(false);
  }

  Future<void> _delete() async {
    final api = AppScope.api(context);
    final navigator = Navigator.of(context);
    final count = widget.doctor.prescriptionCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this doctor card?'),
        content: Text(
          "${widget.doctor.name}'s contact card will be removed. "
          '${count == 1 ? 'The 1 prescription' : 'The $count prescriptions'} from this doctor '
          '${count == 1 ? 'stays' : 'stay'} in your timeline.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete card')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await guarded(context, () => api.deleteDoctor(widget.doctor.id));
    if (ok) navigator.pop(true);
  }

  Widget _field(TextEditingController controller, String label, {String? error, TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, errorText: error, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit doctor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InfoBanner('These details come from your prescription. Check them against the paper copy.'),
          _field(_name, 'Name', error: _name.text.trim().isEmpty ? 'Name is needed' : null),
          _field(_specialty, 'Specialty (optional)'),
          _field(
            _phone,
            'Phone (optional)',
            keyboard: TextInputType.phone,
            error: _phoneValid ? null : 'Check the number',
          ),
          _field(_registration, 'Registration no. (optional)'),
          _field(_availability, 'Availability (optional)'),
          const SizedBox(height: 12),
          Text(
            'Details you enter are not verified by the app.',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _busy ? null : _delete, child: const Text('Delete card')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _valid && !_busy ? _save : null, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}
