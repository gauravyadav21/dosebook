import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../auth/sign_in_screen.dart';
import '../auth/sign_up_screen.dart';
import '../chat/chat_screen.dart';
import '../notes/notes_screen.dart';
import '../profile/profile_screen.dart';
import '../safety/feedback_screen.dart';
import '../timeline/timeline_screen.dart';
import '../today/today_screen.dart';

/// The four main tabs: Today, Timeline, Chat, Notes. Open to visitors too; each tab decides what a visitor sees (S11).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  bool _wasSignedIn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bring phone reminders in line with the confirmed schedules each time the app opens
    // signed in, and when a visitor signs in. A visitor has no reminders to sync.
    final session = AppScope.of(context);
    if (session.signedIn && !_wasSignedIn) session.reminders.sync(session.api);
    _wasSignedIn = session.signedIn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Rebuilt on every switch so each tab shows fresh data.
      body: switch (_index) {
        0 => const TodayScreen(),
        1 => const TimelineScreen(),
        2 => const ChatScreen(),
        _ => const NotesScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Timeline'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.notes), label: 'Notes'),
        ],
      ),
    );
  }
}

/// Account menu shown in the top bar of the main tabs. A visitor gets the way in instead.
class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.person),
      tooltip: 'Account',
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
        } else if (value == 'safety') {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FeedbackScreen()));
        } else if (value == 'signout') {
          session.signOut();
        } else if (value == 'signin') {
          Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => const SignInScreen()));
        } else if (value == 'signup') {
          Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => const SignUpScreen()));
        }
      },
      itemBuilder: (_) => [
        if (!session.signedIn) ...const [
          PopupMenuItem(value: 'signin', child: Text('Sign in')),
          PopupMenuItem(value: 'signup', child: Text('Create account')),
        ] else ...[
        PopupMenuItem(enabled: false, child: Text(session.me?.email ?? '')),
        const PopupMenuItem(value: 'profile', child: Text('My profile')),
        const PopupMenuItem(value: 'safety', child: Text('Feedback on past medicines')),
        const PopupMenuItem(value: 'signout', child: Text('Sign out')),
        ],
      ],
    );
  }
}
