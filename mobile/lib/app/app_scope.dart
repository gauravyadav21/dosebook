import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../reminders/reminders.dart';

/// Who is using the app: a visitor (not signed in) or a signed-in user. Screens read it through [AppScope].
class Session extends ChangeNotifier {
  Session(this.api, {required this.reminders}) {
    api.onUnauthorized = () => signOut(expired: true);
    api.onChanged = dataChanged;
  }

  /// Goes up each time the user's data changes. Every [Loader] reloads when it does,
  /// so a screen never shows stale data after a save made on another screen.
  int revision = 0;

  void dataChanged() {
    revision++;
    notifyListeners();
  }

  static const _tokenKey = 'session_token';
  static const _themeKey = 'theme_mode';

  final Api api;
  final Reminders reminders;

  Me? me;
  bool loading = true;

  /// Light, dark, or follow the phone (S12). Kept on the phone, not in the account.
  ThemeMode themeMode = ThemeMode.system;

  /// True once the intro pages were dismissed in this run of the app, or somebody signed in.
  /// Not saved: the intro is shown on every start until sign-in (S12).
  bool introDone = false;

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  void finishIntro() {
    introDone = true;
    notifyListeners();
  }

  bool get signedIn => api.token != null;

  /// Signed in and past the first-run acknowledgement: the user's own data can be loaded and saved.
  bool get canUse => signedIn && me != null && !me!.ackRequired;

  /// True after a session was ended by the server, until the next sign-in. Visitor screens say so.
  bool sessionEnded = false;

  /// Restores a saved session at start-up. [minimum] keeps the splash from flashing past.
  Future<void> restore({Duration minimum = Duration.zero}) async {
    final shown = Future<void>.delayed(minimum);
    final prefs = await SharedPreferences.getInstance();
    // The appearance comes first, so the splash is already in the chosen mode.
    final saved = prefs.getString(_themeKey);
    final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (mode != null && mode != themeMode) {
      themeMode = mode;
      notifyListeners();
    }
    api.token = prefs.getString(_tokenKey);
    if (api.token != null) {
      introDone = true;
      try {
        me = await api.me();
      } on ApiException catch (e) {
        // Keep the token when the server is merely unreachable; drop it only when it was refused.
        if (e.isUnauthorized) api.token = null;
      }
    }
    await shown;
    loading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password, {required bool register}) async {
    api.token = register ? await api.register(email, password) : await api.login(email, password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, api.token!);
    me = await api.me();
    sessionEnded = false;
    introDone = true;
    notifyListeners();
  }

  Future<void> acknowledge() async {
    me = await api.acknowledge(me!.ackVersion);
    notifyListeners();
  }

  /// Back to visitor mode (S11). [expired] is set when the server refused the session.
  Future<void> signOut({bool expired = false}) async {
    if (api.token == null) return;
    api.token = null;
    me = null;
    sessionEnded = expired;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    // Another person's reminders must not keep firing on this phone.
    await reminders.clear();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<Session> {
  const AppScope({super.key, required Session session, required super.child}) : super(notifier: session);

  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static Api api(BuildContext context) => of(context).api;
}
