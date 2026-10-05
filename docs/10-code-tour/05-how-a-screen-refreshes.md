# Tour 5: how a screen refreshes

Follows no single action. It explains one mechanism used by every screen, and the bug that led to it.

## The bug
After confirming a prescription, the Timeline still showed the old list until you switched tabs. Cause: the Timeline reloaded itself when the Upload screen closed. But the Upload screen is replaced by the Review screen straight after the upload, which is before you confirm. So the reload happened too early and never again. Each screen was refreshing itself by hand after navigation, and each could get the moment wrong.

## The fix: three pieces
### 1. `Api` reports every change
**`mobile/lib/api/api.dart`, `_send`.** After a successful request that is not a GET, it calls `onChanged`. A caller can pass `changes: false` for requests that are not GETs but change none of your data (sign-in, chat). Upload does not report either: it goes through `_read` directly, because an upload alone changes nothing you can see.

### 2. `Session` counts changes
**`mobile/lib/app/app_scope.dart`.** In the constructor, `api.onChanged = dataChanged`. `dataChanged` adds one to `revision` and calls `notifyListeners()`. `revision` is just a number that goes up; its value means nothing, only the fact that it changed.

`AppScope` is an `InheritedNotifier` wrapped around the whole app in `main.dart`. Any widget that called `AppScope.of(context)` is told when the session notifies.

### 3. `Loader` reloads
**`mobile/lib/widgets/common.dart`, `LoaderState`.**
- `didChangeDependencies` runs on first build and again each time the session notifies. It compares the session's `revision` with the one it last saw; if different, it calls `reload()`. This single method covers both the first load and every later change.
- `didChangeAppLifecycleState` reloads when the app comes back to the foreground (`resumed`). `Loader` registers itself as an observer in `initState` and removes itself in `dispose`.
- `build` wraps the content in a `RefreshIndicator`, so pulling down reloads. The `notificationPredicate` lets it react to lists nested inside tabs as well.
- While reloading it keeps showing the old data, so the screen does not flash a spinner. The spinner and the "Try again" error only show before the first successful load.

`ScrollableFill` (same file) wraps fixed content such as an empty state in a scrollable, so pull-to-refresh works there too.

## What a screen has to do
Nothing beyond using `Loader`:
```dart
Loader<List<Prescription>>(
  load: api.prescriptions,
  builder: (context, prescriptions, reload) => ListView(...),
)
```
See `mobile/lib/features/timeline/timeline_screen.dart`. There is no reload after navigation any more. Screens that change data call the `Api` method (through `guarded`, so errors are shown) and do nothing else; the reload follows by itself.

## Following one change through
You tap "Taken" in Today:
1. `today_screen.dart`, `mark` calls `api.markDose`.
2. `Api._send` gets a success and calls `onChanged`.
3. `Session.dataChanged`: `revision` goes from, say, 4 to 5; `notifyListeners()`.
4. Every mounted `Loader` gets `didChangeDependencies`, sees 5 is not 4, and reloads: Today, and also the Timeline sitting underneath, so its "Doses taken" count is right when you go back.

## The cost of this design
Every change reloads every mounted `Loader`, not only the ones affected. With a handful of screens and small lists that is a few cheap requests. With many screens or large lists it would be wasteful, and the next step would be to say which data changed. This was an agent default, chosen for simplicity.

## Tests that prove it
`mobile/test/widget_test.dart`, group "Auto refresh (every screen, through Loader)":
- "an open Timeline updates when a prescription is confirmed elsewhere, without navigating"
- "pull-to-refresh reloads, also on an empty screen"
- "reloads when the app comes back to the foreground"
- "reading data does not trigger a reload loop"

## The rule this became
`.claude/skills/add-screen/SKILL.md` and `docs/03-standards/coding-standards.md`: every screen loads through `Loader`; no fetching in `initState`; no manual reload after navigation.

## Things to try
1. In `api.dart`, remove `changes: false` from `chat`. Run `flutter test`. One chat test checks `revision` and fails; read why.
2. In `LoaderState.didChangeDependencies`, remove the `if`. Run the "reload loop" test. What happens, and why?
3. On the emulator: open Timeline, mark a dose in Today, go back to Timeline and check the count without pulling.

## Check your understanding
1. What tells the Timeline to reload after a confirm made on another screen?
2. Why does chat not cause reloads?
3. What three events make a `Loader` reload?
4. Why is the old data kept on screen during a reload?

Answers: (1) `Api._send` calls `onChanged`, `Session.revision` goes up and notifies, `Loader.didChangeDependencies` sees the new number. (2) `chat` passes `changes: false`. (3) A change in `revision`, the app resuming, and a pull-down; plus the first build. (4) To avoid a flash of spinner on every small change.
