import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../auth/require_sign_in.dart';
import '../doctors/doctors_screen.dart';
import '../upload/upload_screen.dart';
import 'prescription_screen.dart';

/// Confirmed prescriptions, newest first (S3).
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  /// Everything opened from here is the user's own data, so a visitor signs in first (S11).
  Future<void> _push(BuildContext context, Widget screen) async {
    if (!await requireSignIn(context) || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final api = session.api;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts),
            tooltip: 'Doctors',
            onPressed: () => _push(context, const DoctorsScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _push(context, const UploadScreen()),
        icon: const Icon(Icons.upload),
        label: const Text('Upload'),
      ),
      // No manual refresh after navigation: the Loader reloads when a prescription is confirmed.
      body: !session.signedIn
          ? const GuestView(
              icon: Icons.description,
              title: 'Your medicine timeline',
              body: 'Upload a prescription photo or PDF. The app reads it, you check it against the paper, '
                  'and it joins your history, newest first, with the doctor who prescribed it.',
            )
          : Loader<List<Prescription>>(
        load: api.prescriptions,
        builder: (context, prescriptions, reload) {
          if (prescriptions.isEmpty) {
            return const ScrollableFill(
              child: EmptyState(
                icon: Icons.description,
                title: 'No history yet',
                body: 'Upload a prescription photo or PDF to start your medicine timeline.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: prescriptions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => TimelineEntry(
              prescription: prescriptions[i],
              onTap: () => _push(context, PrescriptionScreen(prescriptionId: prescriptions[i].id)),
            ),
          );
        },
      ),
    );
  }
}
