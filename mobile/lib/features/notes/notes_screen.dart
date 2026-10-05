import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../widgets/common.dart';
import '../auth/require_sign_in.dart';
import '../home/home_shell.dart';

/// Open notes: free text the user writes for themselves (S7). The app stores it and does nothing else with it.
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

/// One text field. Nothing else.
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final _text = TextEditingController(text: widget.note?.text ?? '');
  bool _busy = false;

  static const maxLength = 5000;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final api = AppScope.api(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => widget.note == null ? api.createNote(_text.text) : api.updateNote(widget.note!.id, _text.text),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) navigator.pop();
  }

  Future<void> _delete() async {
    final api = AppScope.api(context);
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
    if (ok) navigator.pop();
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
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _text,
          autofocus: !editing,
          maxLength: maxLength,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Write your note', border: InputBorder.none),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }
}
