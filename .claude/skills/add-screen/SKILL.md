---
name: add-screen
description: Add or change a screen in the Flutter app. Use whenever a screen that shows server data is created or edited, so it refreshes itself and follows the app's rules.
---

Input: the story and, if one exists, the Figma frame (`docs/02-architecture/design.md`).

Every screen that shows server data must refresh by itself. The user never has to switch screens to see a change.

1. Load data only through `Loader` (`mobile/lib/widgets/common.dart`). It gives the screen, with no extra code: a spinner, an error message with "Try again", pull-to-refresh, a reload whenever data changes anywhere in the app, and a reload when the app returns to the foreground. Do not fetch in `initState`, and do not call `reload()` after navigation.
2. The `Loader` builder returns a scrollable. For an empty state or other fixed content, wrap it in `ScrollableFill` so pull-to-refresh still works.
3. Change data only through `Api` (`mobile/lib/api/api.dart`). A successful change notifies every open `Loader`. A new call that is not a GET but changes nothing the user sees (like chat) passes `changes: false`.
4. Run a change through `guarded(...)` so the server's error message is shown. Never fail silently.
5. After a change that affects doses (confirm, mark, edit or stop a course, own reminders), call `session.reminders.sync(session.api)`.
6. Wording about what the app is and is not comes from `mobile/lib/app/wording.dart`. Do not paraphrase it on a screen. Self-added items always show the Self-added tag.
7. Colours and text styles come from the theme, never a fixed colour in a screen: the app has light and dark mode (S12). Only the logo and splash use the fixed `brandScheme` from `mobile/lib/app/theme.dart`. Look at a new screen once in dark mode. Phone features (file picker, dialler, share) go through `mobile/lib/app/platform.dart`.
8. The app opens without sign-in (S11). Say for each screen whether a visitor can see it. A tab checks `session.signedIn` before building its `Loader` and shows `GuestView` (`mobile/lib/features/auth/require_sign_in.dart`) to a visitor, so no request is sent. Every action that saves or loads the user's own data starts with `if (!await requireSignIn(context) || !context.mounted) return;`.
9. Widget test in `mobile/test/widget_test.dart` using `pumpScreen` (412 px wide) and `FakeBackend`: the loaded state, the empty state, one failed request, that the screen updates after a change without navigating, and for a tab or a gated action, what a visitor sees (`signedIn: false`) and that nothing is sent.
10. Run `flutter analyze && flutter test`. Add the screen to `docs/02-architecture/design.md`.
