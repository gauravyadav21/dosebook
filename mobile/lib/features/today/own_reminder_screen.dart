import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../app/wording.dart';
import '../../widgets/common.dart';
import '../../widgets/pick_time.dart';

/// Add or edit the user's own reminder for a medicine they take themselves (S7).
/// It is always labelled as the user's own, never as prescribed. Pops `true` when something changed.
class OwnReminderScreen extends StatefulWidget {
  const OwnReminderScreen({super.key, this.reminder});

  final Medicine? reminder;

  @override
  State<OwnReminderScreen> createState() => _OwnReminderScreenState();
}

class _OwnReminderScreenState extends State<OwnReminderScreen> {
  late final _name = TextEditingController(text: widget.reminder?.name ?? '');
  late final _dose = TextEditingController(text: widget.reminder?.dose ?? '');
  late final Set<String> _slots = {...?widget.reminder?.schedule?.slots};
  late final List<String> _times = [...?widget.reminder?.schedule?.times];
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty && (_slots.isNotEmpty || _times.isNotEmpty);

  Future<void> _addTime() async {
    final value = await pickClockTime(context, defaultSlotTimes['MORNING']!);
    if (value == null || !mounted) return;
    if (!_times.contains(value)) setState(() => _times..add(value)..sort());
  }

  Future<void> _save() async {
    final api = AppScope.api(context);
    final navigator = Navigator.of(context);
    // The dose goes to the server exactly as typed; the app never checks or corrects it.
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'dose': _dose.text,
      'slots': slotOrder.where(_slots.contains).toList(),
      'times': _times,
      if (widget.reminder == null) 'startDate': isoDate(DateTime.now()),
    };
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => widget.reminder == null ? api.createOwnReminder(body) : api.updateOwnReminder(widget.reminder!.id, body),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) navigator.pop(true);
  }

  Future<void> _delete() async {
    final api = AppScope.api(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete the reminder for ${widget.reminder!.name}?'),
        content: const Text('It is removed from Today and no longer reminds you.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await guarded(context, () => api.deleteOwnReminder(widget.reminder!.id));
    if (ok) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final editing = widget.reminder != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit my reminder' : 'Add my reminder')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          const Align(alignment: Alignment.centerLeft, child: SourceTag(selfAdded: true)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Medicine name', counterText: '', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dose,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Dose (optional, your own words)',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Remind me', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final slot in slotOrder)
                FilterChip(
                  label: Text(slotLabel(slot)),
                  selected: _slots.contains(slot),
                  onSelected: (on) => setState(() => on ? _slots.add(slot) : _slots.remove(slot)),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final time in _times)
                InputChip(label: Text(clockFromText(time)), onDeleted: () => setState(() => _times.remove(time))),
              ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Add a time'), onPressed: _addTime),
            ],
          ),
          if (_slots.isEmpty && _times.isEmpty) ...[
            const SizedBox(height: 8),
            Text('Choose at least one time.', style: text.bodyMedium?.copyWith(color: scheme.error)),
          ],
          const SizedBox(height: 12),
          const InfoBanner(ownReminder),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (editing) TextButton(onPressed: _busy ? null : _delete, child: const Text('Delete')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _valid && !_busy ? _save : null, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}
