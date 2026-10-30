import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../app/tokens.dart';
import '../../widgets/common.dart';
import '../auth/require_sign_in.dart';
import '../home/home_shell.dart';
import 'reminder_sheet.dart';

/// Open notes: free text the user writes for themselves (S7). The app stores it and does nothing else with it,
/// except the reminder the user may ask for on a note (S15).
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  Future<void> _open(BuildContext context, [Note? note]) async {
    if (!await requireSignIn(context) || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NoteEditScreen(note: note)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notes'), actions: const [AccountMenu()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
      body: !AppScope.of(context).signedIn
          ? const GuestView(
              icon: Icons.notes,
              title: 'Your own notes',
              body: 'Write anything you want to remember, such as questions for your next doctor visit. '
                  'Notes are plain text and only you can see them.',
            )
          : Loader<List<Note>>(
        load: AppScope.api(context).notes,
        builder: (context, notes, reload) {
          if (notes.isEmpty) {
            return const ScrollableFill(
              child: EmptyState(
                icon: Icons.notes,
                title: 'No notes yet',
                body: 'Write anything you want to remember, such as questions for your next doctor visit.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final note = notes[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _open(context, note),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.text, maxLines: 4, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                        const SizedBox(height: 8),
                        if (note.reminder != null) ...[
                          Row(
                            children: [
                              Icon(Icons.notifications_active_outlined, size: Space.lg, color: scheme.tertiary),
                              Gap.sm,
                              Expanded(
                                child: Text(
                                  noteReminderWords(note.reminder!),
                                  style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                          Gap.xs,
                        ],
                        Text(
                          'Edited ${prettyDate(isoDate(note.updatedAt))}',
                          style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// One text field, and an optional reminder (S15).
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final _text = TextEditingController(text: widget.note?.text ?? '');
  bool _busy = false;

  // The reminder, chosen in the sheet. Off (null) until the user switches it on.
  late NoteReminder? _reminder = widget.note?.reminder;

  static const maxLength = 5000;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = AppScope.of(context);
    final api = session.api;
    final navigator = Navigator.of(context);
    final reminder = _reminder;
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => widget.note == null
          ? api.createNote(_text.text, reminder: reminder)
          : api.updateNote(widget.note!.id, _text.text, reminder: reminder),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      // Move the phone's notifications to match what was just saved.
      session.reminders.sync(api);
      navigator.pop();
    }
  }

  /// Opens the reminder sheet. Closing it without choosing changes nothing.
  Future<void> _editReminder() async {
    final choice = await showReminderSheet(context, current: _reminder);
    if (choice != null && mounted) setState(() => _reminder = choice.reminder);
  }

  Future<void> _delete() async {
    final session = AppScope.of(context);
    final api = session.api;
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await guarded(context, () => api.deleteNote(widget.note!.id));
    if (ok) {
      session.reminders.sync(api);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit note' : 'New note'),
        actions: [
          if (editing) IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete note', onPressed: _busy ? null : _delete),
          TextButton(
            onPressed: _text.text.trim().isNotEmpty && !_busy ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: Space.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                autofocus: !editing,
                maxLength: maxLength,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write your note',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Gap.sm,
            _ReminderRow(reminder: _reminder, onOpen: _editReminder, onOff: () => setState(() => _reminder = null)),
          ],
        ),
      ),
    );
  }
}

/// "Remind me": off by default. Switching it on, or tapping the row, opens the sheet with every choice (S15).
class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder, required this.onOpen, required this.onOff});

  final NoteReminder? reminder;
  final VoidCallback onOpen;
  final VoidCallback onOff;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: Space.card,
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: scheme.tertiary),
              Gap.md,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remind me', style: text.titleMedium),
                    Text(
                      reminder == null ? 'Off' : noteReminderWords(reminder!),
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(value: reminder != null, onChanged: (on) => on ? onOpen() : onOff()),
            ],
          ),
        ),
      ),
    );
  }
}
