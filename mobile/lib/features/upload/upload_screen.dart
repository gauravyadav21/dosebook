import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../app/app_scope.dart';
import '../../app/platform.dart';
import '../../app/wording.dart';
import '../../widgets/common.dart';
import 'review_screen.dart';

/// Pick a prescription photo or PDF and send it for reading (S1).
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, this.demo = demoBuild});

  /// Shows the demo-server note. Set by the build; a parameter so tests can turn it on.
  final bool demo;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _uploading;
  String? _error;

  Future<void> _pick() async {
    final api = AppScope.api(context);
    final navigator = Navigator.of(context);
    setState(() => _error = null);
    try {
      final file = await pickPrescriptionFile();
      if (file == null) return;
      setState(() => _uploading = file.name);
      final document = await api.upload(file.bytes, file.name);
      if (!mounted) return;
      // The review screen replaces this one, so Back from review does not re-upload.
      await navigator.pushReplacement(MaterialPageRoute<void>(builder: (_) => ReviewScreen(document: document)));
    } catch (e) {
      if (mounted) setState(() => _error = '$e Nothing was stored.');
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Upload prescription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.demo) ...[const InfoBanner(demoUploadNote), const SizedBox(height: 16)],
          Text(
            'Photo or PDF of one prescription. JPEG, PNG or PDF, up to 10 MB.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(
              children: [
                Icon(Icons.image, size: 40, color: scheme.primary),
                const SizedBox(height: 12),
                Text('Choose a photo or PDF', style: text.titleMedium),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _uploading == null ? _pick : null,
                  child: const Text('Browse files'),
                ),
              ],
            ),
          ),
          if (_uploading != null) ...[
            const SizedBox(height: 16),
            Text('Uploading', style: text.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: Text(_uploading!),
                subtitle: const Text('Uploading and reading. This can take a few seconds.'),
              ),
            ),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, size: 20, color: scheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_error!, style: text.bodyMedium?.copyWith(color: scheme.onErrorContainer)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
