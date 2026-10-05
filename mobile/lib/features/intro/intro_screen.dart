import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/wording.dart';
import '../../widgets/common.dart';
import '../../widgets/logo.dart';
import '../auth/sign_in_screen.dart';

class _Page {
  const _Page(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    Icons.description,
    'Your prescriptions in one timeline',
    'Upload a photo or PDF of a prescription. The app reads it, you check it against the paper, '
        'and it joins your history with the doctor who prescribed it.',
  ),
  _Page(
    Icons.alarm,
    'Reminders as written on your prescription',
    'Your phone reminds you of each dose from the schedule you confirmed. '
        'Mark it Taken or Skipped. The app never changes a dose.',
  ),
  _Page(
    Icons.chat_bubble_outline,
    'What worked for you',
    'Describe a minor symptom to see what your own doctors prescribed you for it before, '
        'or look up what a medicine is usually prescribed for and how to keep it.',
  ),
];

/// Intro pages: what the app does, and last, what it never does (S12).
/// Shown at start to a visitor until someone signs in, and from "About DoseBook" in the account menu.
/// It shows no personal data and sends no request. It is information only; the recorded
/// acknowledgement is still [FirstRunScreen] after sign-up (S8).
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.pushed = false});

  /// True when opened from the account menu: closing returns to the previous screen.
  final bool pushed;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _count = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (widget.pushed) {
      Navigator.of(context).pop();
    } else {
      AppScope.of(context).finishIntro();
    }
  }

  void _next() {
    if (_page == _count - 1) return _close();
    _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _signIn() {
    // The navigator outlives this screen, which is replaced by the tabs as soon as the intro ends.
    final navigator = Navigator.of(context);
    AppScope.of(context).finishIntro();
    navigator.push(MaterialPageRoute<bool>(builder: (_) => const SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final session = AppScope.of(context);
    final last = _page == _count - 1;

    Widget feature(_Page page, {required bool first}) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (first)
              const AppLogo(size: 96, badge: true)
            else
              CircleAvatar(
                radius: 48,
                backgroundColor: scheme.primaryContainer,
                child: Icon(page.icon, size: 40, color: scheme.onPrimaryContainer),
              ),
            const SizedBox(height: 24),
            Text(page.title, style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              page.body,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        );

    Widget limits() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: scheme.errorContainer,
                child: Icon(Icons.block, size: 40, color: scheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 24),
            Center(child: Text('What DoseBook never does', style: text.headlineSmall, textAlign: TextAlign.center)),
            const SizedBox(height: 4),
            for (final line in doesNotLines)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.close, size: 20, color: scheme.error),
                    const SizedBox(width: 12),
                    Expanded(child: Text(line, style: text.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const InfoBanner(firstRunBanner),
          ],
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              // Fixed height, so the pages do not jump when Skip leaves on the last page.
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    if (!widget.pushed && !session.signedIn)
                      TextButton(onPressed: _signIn, child: const Text('Sign in')),
                    const Spacer(),
                    if (!last) TextButton(onPressed: _close, child: const Text('Skip')),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: i < _pages.length ? feature(_pages[i], first: i == 0) : limits(),
                  ),
                ),
              ),
            ),
            Semantics(
              label: 'Page ${_page + 1} of $_count',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _count; i++)
                    Container(
                      width: i == _page ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == _page ? scheme.primary : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _next, child: Text(last ? 'Get started' : 'Next')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
