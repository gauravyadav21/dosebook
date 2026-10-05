import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/wording.dart';
import '../../widgets/common.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Gate for anything that saves or loads the user's own data (S11).
/// Signed in: returns true at once. Otherwise opens sign-in and returns true only if the
/// visitor ends up signed in and past the first-run acknowledgement, so the caller can continue.
Future<bool> requireSignIn(BuildContext context) async {
  final session = AppScope.of(context);
  if (!session.canUse) {
    await Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => const SignInScreen()));
  }
  return session.canUse;
}

/// What a tab shows to a visitor who is not signed in: what the tab is for, and the way in.
/// It shows no data and sends no request.
class GuestView extends StatelessWidget {
  const GuestView({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    return Center(
      child: SingleChildScrollView(
        // Room for the floating button of the tab.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.sessionEnded) const InfoBanner(sessionEnded),
            EmptyState(icon: icon, title: title, body: body),
            FilledButton(onPressed: () => _open(context, const SignInScreen()), child: const Text('Sign in')),
            const SizedBox(height: 8),
            TextButton(onPressed: () => _open(context, const SignUpScreen()), child: const Text('Create account')),
          ],
        ),
      ),
    );
  }
}
