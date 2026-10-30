import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../app/platform.dart';
import '../../widgets/common.dart';

const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const _sexLabels = {'FEMALE': 'Female', 'MALE': 'Male', 'OTHER': 'Other'};

/// Whole years between [dateOfBirth] (YYYY-MM-DD) and [today].
int? ageOn(String? dateOfBirth, DateTime today) {
  final born = DateTime.tryParse(dateOfBirth ?? '');
  if (born == null) return null;
  var age = today.year - born.year;
  if (today.month < born.month || (today.month == born.month && today.day < born.day)) age--;
  return age < 0 ? null : age;
}

/// The user's own record of themselves, plus their allergies (S10, S4).
/// The app stores these details. It does not judge or advise from them.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AppScope.api(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: Loader<(Profile, List<Allergy>)>(
        load: () async => (await api.profile(), await api.allergies()),
        // The form is rebuilt only when the saved profile itself changes, so adding an allergy
        // does not discard profile fields the user is still typing.
        builder: (context, data, reload) =>
            _ProfileForm(key: ValueKey(data.$1.toJson().toString()), profile: data.$1, allergies: data.$2),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({super.key, required this.profile, required this.allergies});

  final Profile profile;
  final List<Allergy> allergies;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final _name = TextEditingController(text: widget.profile.name ?? '');
  late final _height = TextEditingController(text: _number(widget.profile.heightCm));
  late final _weight = TextEditingController(text: _number(widget.profile.weightKg));
  late final _emergencyName = TextEditingController(text: widget.profile.emergencyName ?? '');
  late final _emergencyPhone = TextEditingController(text: widget.profile.emergencyPhone ?? '');
  late final _conditions = TextEditingController(text: widget.profile.conditions ?? '');
  final _newAllergy = TextEditingController();
  late String? _dateOfBirth = widget.profile.dateOfBirth;
  late String? _sex = widget.profile.sex;
  late String? _bloodGroup = widget.profile.bloodGroup;
  bool _busy = false;

  static final _phonePattern = RegExp(r'^\+?[0-9][0-9 ()-]{5,19}$');

  static String _number(double? value) =>
      value == null ? '' : (value == value.roundToDouble() ? value.toInt().toString() : value.toString());

  @override
  void dispose() {
    for (final c in [_name, _height, _weight, _emergencyName, _emergencyPhone, _conditions, _newAllergy]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Null when empty; NaN marks text that is not a number in range.
  double? _parse(TextEditingController c, double min, double max) {
    final raw = c.text.trim();
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    return (value == null || value < min || value > max) ? double.nan : value;
  }

  double? get _heightValue => _parse(_height, 30, 272);
  double? get _weightValue => _parse(_weight, 1, 500);
  bool get _phoneValid => _emergencyPhone.text.trim().isEmpty || _phonePattern.hasMatch(_emergencyPhone.text.trim());
  bool get _valid => !(_heightValue?.isNaN ?? false) && !(_weightValue?.isNaN ?? false) && _phoneValid;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateOfBirth ?? '') ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dateOfBirth = isoDate(picked));
  }

  Future<void> _save() async {
    final api = AppScope.api(context);
    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    // One decimal place at most, as the server expects.
    double? rounded(double? v) => v == null ? null : (v * 10).round() / 10;
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => api.saveProfile(Profile(
        name: optional(_name),
        dateOfBirth: _dateOfBirth,
        sex: _sex,
        heightCm: rounded(_heightValue),
        weightKg: rounded(_weightValue),
        bloodGroup: _bloodGroup,
        emergencyName: optional(_emergencyName),
        emergencyPhone: optional(_emergencyPhone),
        conditions: optional(_conditions),
      )),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) showMessage(context, 'Profile saved');
  }

  Future<void> _addAllergy() async {
    final name = _newAllergy.text.trim();
    if (name.isEmpty) return;
    final api = AppScope.api(context);
    if (await guarded(context, () => api.addAllergy(name))) _newAllergy.clear();
  }

  Widget _field(TextEditingController controller, String label,
          {String? error, String? suffix, TextInputType? keyboard, int maxLines = 1, int maxLength = 120}) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          suffixText: suffix,
          counterText: '',
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    final api = AppScope.api(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final age = ageOn(_dateOfBirth, DateTime.now());
    final phone = _emergencyPhone.text.trim();
    const gap = SizedBox(height: 12);
    const decimal = TextInputType.numberWithOptions(decimal: true);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.profile.email, style: muted),
        gap,
        Text('About me', style: text.titleMedium),
        gap,
        _field(_name, 'Name'),
        gap,
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of birth',
                    helperText: age == null ? null : 'Age $age',
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(_dateOfBirth == null ? 'Choose' : prettyDate(_dateOfBirth!), style: text.bodyLarge),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _sex,
                decoration: InputDecoration(
                  labelText: 'Sex',
                  helperText: age == null ? null : '',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Not set')),
                  for (final entry in _sexLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (value) => setState(() => _sex = value),
              ),
            ),
          ],
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                _height,
                'Height',
                suffix: 'cm',
                keyboard: decimal,
                maxLength: 6,
                error: (_heightValue?.isNaN ?? false) ? '30 to 272 cm' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _weight,
                'Weight',
                suffix: 'kg',
                keyboard: decimal,
                maxLength: 6,
                error: (_weightValue?.isNaN ?? false) ? '1 to 500 kg' : null,
              ),
            ),
          ],
        ),
        gap,
        DropdownButtonFormField<String?>(
          initialValue: _bloodGroup,
          decoration: const InputDecoration(labelText: 'Blood group', border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: null, child: Text('Not set')),
            for (final group in bloodGroups) DropdownMenuItem(value: group, child: Text(group)),
          ],
          onChanged: (value) => setState(() => _bloodGroup = value),
        ),
        gap,
        _field(_conditions, 'Long-term conditions (your own words)', maxLines: 3, maxLength: 500),
        const SizedBox(height: 24),
        Text('Emergency contact', style: text.titleMedium),
        gap,
        _field(_emergencyName, 'Contact name'),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                _emergencyPhone,
                'Contact phone',
                keyboard: TextInputType.phone,
                maxLength: 20,
                error: _phoneValid ? null : 'Check the number',
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.tonal(
                onPressed: phone.isEmpty || !_phoneValid ? null : () => openDialler(phone),
                child: const Text('Call'),
              ),
            ),
          ],
        ),
        gap,
        Text('These details are your own record. The app does not check them or advise from them.', style: muted),
        gap,
        FilledButton(onPressed: _valid && !_busy ? _save : null, child: const Text('Save profile')),
        const SizedBox(height: 24),
        Text('Allergies', style: text.titleMedium),
        gap,
        Text('Matching medicines are left out of chat answers. Allergies are saved as you add them.', style: muted),
        gap,
        for (final allergy in widget.allergies)
          Card(
            child: ListTile(
              title: Text(allergy.name),
              subtitle: const Text('Excluded from chat answers'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove ${allergy.name}',
                onPressed: () => guarded(context, () => api.deleteAllergy(allergy.id)),
              ),
            ),
          ),
        gap,
        TextField(
          controller: _newAllergy,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addAllergy(),
          decoration: InputDecoration(
            labelText: 'Add an allergy',
            counterText: '',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(icon: const Icon(Icons.add), tooltip: 'Add allergy', onPressed: _addAllergy),
          ),
        ),
      ],
    );
  }
}
