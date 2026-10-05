import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../auth/require_sign_in.dart';
import '../home/home_shell.dart';
import 'own_reminder_screen.dart';

/// Doses due today, grouped by part of day, with Taken / Skipped (S6, S7).
/// The user's own reminders are added and edited from here.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, this.now});

  /// Fixed clock for tests.
  final DateTime? now;

  Future<void> _openReminder(BuildContext context, [Medicine? reminder]) async {
    final session = AppScope.of(context);
    if (!await requireSignIn(context) || !context.mounted) return;
    final changed = await Navigator.of(context)
        .push(MaterialPageRoute<bool>(builder: (_) => OwnReminderScreen(reminder: reminder)));
    if (changed == true) await session.reminders.sync(session.api);
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final day = now ?? DateTime.now();
    final date = isoDate(day);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Today'), actions: const [AccountMenu()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReminder(context),
        icon: const Icon(Icons.add_alarm),
        label: const Text('My reminder'),
      ),
      body: !session.signedIn
          ? const GuestView(
              icon: Icons.today,
              title: 'Your doses for today',
              body: 'After you confirm a prescription, the doses due each day appear here to mark Taken or Skipped, '
                  'and your phone reminds you. You can add your own reminders too.',
            )
          : Loader<(List<Dose>, List<Medicine>)>(
        load: () async => (await session.api.today(date), await session.api.ownReminders()),
        builder: (context, data, reload) {
          final (doses, ownReminders) = data;
          if (doses.isEmpty) {
            return const ScrollableFill(
              child: EmptyState(
                icon: Icons.today,
                title: 'No doses due today',
                body: 'Doses appear here once you confirm a prescription schedule or add your own reminder.',
              ),
            );
          }
          final marked = doses.where((d) => d.status != 'DUE').length;

          Future<void> mark(Dose dose, String status) async {
            // The list reloads by itself once the mark is saved.
            final ok = await guarded(
              context,
              () => session.api.markDose(medicineId: dose.medicineId, date: date, slot: dose.slot, status: status),
            );
            // A marked dose needs no follow-up notification.
            if (ok) await session.reminders.sync(session.api);
          }

          Medicine? ownReminderFor(Dose dose) {
            if (!dose.isOwnReminder) return null;
            for (final r in ownReminders) {
              if (r.id == dose.medicineId) return r;
            }
            return null;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                '${longDay(day)} · $marked of ${doses.length} doses marked',
                style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              for (final group in slotOrder)
                if (doses.any((d) => d.group == group)) ...[
                  const SizedBox(height: 12),
                  Text(slotLabel(group), style: text.titleMedium),
                  const SizedBox(height: 4),
                  for (final dose in doses.where((d) => d.group == group))
                    DoseRow(
                      dose: dose,
                      onMark: (status) => mark(dose, status),
                      onEdit: ownReminderFor(dose) == null ? null : () => _openReminder(context, ownReminderFor(dose)),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}
