import 'package:flutter/material.dart';

import 'api/api.dart';
import 'app/app_scope.dart';
import 'app/theme.dart';
import 'features/home/home_shell.dart';
import 'features/intro/intro_screen.dart';
import 'features/onboarding/first_run_screen.dart';
import 'features/splash/splash_screen.dart';
import 'reminders/reminders.dart';
import 'widgets/dismiss_keyboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(Api(), reminders: LocalReminders());
  runApp(App(session: session));
  session.restore(minimum: const Duration(milliseconds: 900));
}

class App extends StatelessWidget {
  const App({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: session,
      // Rebuilt when the session changes, so a new appearance choice applies at once (S12).
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) => MaterialApp(
          title: 'DoseBook',
          theme: appTheme(Brightness.light),
          darkTheme: appTheme(Brightness.dark),
          themeMode: session.themeMode,
          builder: dismissKeyboardBuilder,
          home: const _Root(),
        ),
      ),
    );
  }
}

/// Chooses the first screen: the splash while starting, then the app. A visitor sees the intro pages
/// (S12) and then browses the tabs without signing in (S11); a signed-in user sees the one-time
/// acknowledgement first (S8).
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    if (session.loading) return const SplashScreen();
    if (session.signedIn) {
      final me = session.me;
      if (me == null) return const _Offline();
      if (me.ackRequired) return const FirstRunScreen();
    } else if (!session.introDone) {
      return const IntroScreen();
    }
    return const HomeShell();
  }
}

/// Signed in, but the server could not be reached at start-up.
class _Offline extends StatelessWidget {
  const _Offline();

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not reach the server. Check your connection and try again.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: session.restore, child: const Text('Try again')),
              TextButton(onPressed: session.signOut, child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}
