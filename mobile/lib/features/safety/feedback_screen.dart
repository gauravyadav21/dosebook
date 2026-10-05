import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';

/// Feedback on every medicine from confirmed prescriptions (S4). It decides what chat may recall.
/// The same chips are on each prescription; this screen lists all medicines in one place.
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AppScope.api(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback on past medicines')),
      body: Loader<List<Medicine>>(
        load: api.medicines,
        builder: (context, medicines, reload) {
          if (medicines.isEmpty) {
            return const ScrollableFill(
              child: EmptyState(
                icon: Icons.thumbs_up_down_outlined,
                title: 'Nothing to rate yet',
                body: 'Medicines from your confirmed prescriptions appear here.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Medicines marked "Did not work" or "Side effect" are left out when chat recalls what you took before.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              for (final m in medicines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MedicineCard(
                    name: m.name,
                    selfAdded: false,
                    dose: dotted([m.dose, m.frequency]),
                    meta: dotted([m.prescriber, m.date == null ? null : prettyDate(m.date!), m.condition]),
                    footer: switch (m.feedback) {
                      null => 'No feedback recorded',
                      'WORKED' => 'Your feedback: Worked',
                      _ => 'Your feedback: ${feedbackLabel(m.feedback)}. Not recalled in chat.',
                    },
                    feedback: m.feedback,
                    onFeedback: (value) => guarded(context, () => api.setFeedback(m.id, value)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
