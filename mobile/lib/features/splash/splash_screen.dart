import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/wording.dart';
import '../../widgets/logo.dart';

/// Shown while the app starts and the saved session is restored (S11).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Brand colours in both light and dark mode, to match the Android launch screen.
    final scheme = brandScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 144),
              const SizedBox(height: 8),
              Text('DoseBook', style: text.headlineMedium?.copyWith(color: scheme.onPrimary)),
              const SizedBox(height: 12),
              Text(
                tagline,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.primaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
