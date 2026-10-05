import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/wording.dart';
import '../../widgets/common.dart';

/// Shown once per user, and again if the wording version changes (S8).
class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({super.key});

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  bool _busy = false;

  static const _does = [
    'Stores your prescriptions and builds your timeline',
    'Recalls medicines your own doctors prescribed you before',
    'Reminds you of doses exactly as written on your prescription',
  ];
  static const _doesNot = [
    'It does not diagnose',
    'It does not prescribe or suggest new medicines',
    'It does not change a dose or replace your doctor',
  ];

  Future<void> _acknowledge() async {
    setState(() => _busy = true);
    await guarded(context, AppScope.of(context).acknowledge);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget bullet(String line, {required bool positive}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(positive ? Icons.check : Icons.close, size: 20, color: positive ? scheme.primary : scheme.error),
              const SizedBox(width: 12),
              Expanded(child: Text(line, style: text.bodyMedium)),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your medicine memory', style: text.headlineSmall),
                      const SizedBox(height: 16),
                      Text(
                        'A patient-side companion that makes you more aware of your own medicines: '
                        'what you took, when, and what worked for you.',
                        style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Text('What this app does', style: text.titleMedium),
                      for (final line in _does) bullet(line, positive: true),
                      const SizedBox(height: 16),
                      Text('What this app does not do', style: text.titleMedium),
                      for (final line in _doesNot) bullet(line, positive: false),
                      const SizedBox(height: 16),
                      const InfoBanner(firstRunBanner),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _busy ? null : _acknowledge, child: const Text('I understand')),
            ],
          ),
        ),
      ),
    );
  }
}
