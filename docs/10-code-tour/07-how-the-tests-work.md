# Tour 7: how the tests work

The tests are the fastest way into this code: each test name is one sentence about what the code must do. This tour explains the three kinds, how the helpers work, and how to run and read them.

## Three kinds
| Kind | Files | What it runs | What it proves |
|---|---|---|---|
| Unit | `backend/src/**/*.spec.ts`, `mobile/test/logic_test.dart` | One function, no server, no database | A rule is right: course maths, chat rules, doctor matching, the dose filter, reminder planning |
| End-to-end | `backend/test/*.e2e-spec.ts` | The whole backend through real HTTP against a real PostgreSQL | A story works from request to database, including validation, the guard and "another user" |
| Widget | `mobile/test/widget_test.dart` | One screen, drawn at phone width, with a fake server | The screen shows the right thing and sends the right request |

None of them proves the app and the real backend work together on a phone. That is checked by hand on the emulator.

## Backend end-to-end tests
**`backend/vitest.config.e2e.ts`** sets test-only environment values (test database, a signing value, very high rate limits, no Gemini key) and runs `globalSetup`.

**`backend/test/support/global-setup.ts`** applies the migrations to the test database once, before any test file.

**`backend/test/support/app.ts`** is the helper file:
- `createApp()` boots the real application with the same `configureApp` that `main.ts` uses, so tests go through the real validation pipe and guards. It can swap one piece: `createApp((b) => b.overrideProvider(EXTRACTOR).useValue(...))` replaces the extractor.
- `signUp(app)` registers a brand-new fake user with a random email and returns its token. Because every test uses its own user, tests never see each other's data, need no clean-up, and can run in parallel.
- `upload`, `confirmBody`, `schedule`, `confirmed` build the common steps.
- `PNG`, `JPEG`, `PDF` are the smallest byte strings that pass the file-type check.

A typical test (`backend/test/doses.e2e-spec.ts`):
```ts
it('has doses on every day of the course and none before or after', async () => {
  const user = await signUp(app);
  await confirmed(app, user);
  expect(await today(user, '2026-09-30')).toEqual([]);
  expect(await today(user, '2026-10-01')).toHaveLength(4);
  ...
```
Sign up, do the action through HTTP, check the answer.

`it.each([...])` runs the same test for a list of inputs. The long tables of invalid schedules and dosage phrasings use it.

## Faking Gemini
No test calls the real service.
- `backend/src/medicine-info/medicine-info.spec.ts` and `backend/src/extraction/extraction.spec.ts` pass a fake `fetch` into the class and check what was sent and how the reply is handled.
- `backend/test/chat.e2e-spec.ts` replaces the provider with a recorder, so it can check "called once, then never again".

This is why two real faults (a retired model name, an overloaded model) were found only when the real service was called. A mocked test proves your handling of a reply, not that the service answers.

## Widget tests
**`mobile/test/support/fake_backend.dart`**:
- `FakeBackend` is an in-memory server. `backend.on('GET /notes', (_) => [...])` registers a reply; `Reply(400, {...})` gives a non-200 answer; `backend.bodies('POST /notes')` returns what the screen sent.
- `pumpScreen(tester, backend, SomeScreen())` draws the screen inside the app scope at 412 × 917, the size of the designs, and waits for loading to finish.
- `RecordingReminders` counts reminder syncs instead of touching the phone.
- `medicineJson`, `prescriptionJson`, `doseJson`, `doctorJson` build fake server replies.

A typical test:
```dart
testWidgets('marks a dose taken, reloads and re-syncs reminders', (tester) async {
  final backend = FakeBackend()
    ..on('GET /doses/today', (_) => {...})
    ..on('POST /doses/mark', (_) { status = 'TAKEN'; return {}; });
  final app = await pumpScreen(tester, backend, TodayScreen(now: now));
  await tester.tap(find.widgetWithText(FilledButton, 'Taken'));
  await tester.pumpAndSettle();
  expect(backend.bodies('POST /doses/mark').single, {...});
```
Because the fake speaks real JSON through the real `Api`, the JSON parsing in `models.dart` is tested too.

Phone features are swapped by assigning to the variables in `mobile/lib/app/platform.dart`: `openDialler = (phone) async { dialled = phone; return true; };`.

Two things that trip people up, both met in this project:
- A list builds only what is near the screen. An item further down exists in the data but not on screen: scroll to it with the `reveal` helper, or look with `skipOffstage: false`.
- Text fields are scrollable too, so "the scrollable" is ambiguous; `reveal` names the first one.

## Running them
```
cd backend
npm test                                  # unit
npm run test:e2e                          # end-to-end (needs: npm run db:start)
npx vitest run src/chat/chat.rules.spec.ts            # one file
npx vitest run -t "refuses an expired token" --config ./vitest.config.e2e.ts   # one test by name

cd mobile
flutter test                              # all
flutter test --plain-name "marks a dose taken"        # one test by name
```

## Reading a failure
A failing test prints its name, what was expected and what was received, and the line. Start from the name: it tells you which rule broke. Then read the "expected / received" pair. Only then open the code. Two real examples from this build:
- "rejects missing doctor with 400 … expected 400, got 500": the server crashed instead of refusing. The fix was a validation rule, not a test change.
- "A RenderFlex overflowed by 89 pixels on the right": two buttons did not fit at phone width. The fix was in the layout.

When a test fails, decide which is wrong, the code or the test. Changing the test to pass is only right when the rule itself changed.

## What the tests do not cover
See `docs/06-qa/qa-strategy.md`. The main gaps: the app against the real backend on a device, notification timing, the live Gemini call for reading photos, and any review of these tests by a person. The same agent wrote the code and the tests, alongside each other, so a misunderstanding of a story would be in both.

## Things to try
1. Pick one story in `docs/01-requirements/stories/`. For each acceptance criterion, find the test that covers it. Note any criterion with no test.
2. Break one rule on purpose (Tours 1-6 suggest several) and predict which test fails before running.
3. Write one new negative test for the profile (for example a weight of `-5`) by copying a row in `backend/test/profile.e2e-spec.ts`.
4. Run one widget test by name and read its output.

## Check your understanding
1. Why can the end-to-end files run at the same time on one database?
2. What does a widget test prove that an end-to-end test does not, and the other way round?
3. Why did mocked tests miss the retired Gemini model?
4. A test fails after you change a rule on purpose. What do you do?

Answers: (1) Every test registers its own user and all data is filtered by user. (2) Widget: the screen shows and sends the right things; end-to-end: the server enforces the rules and saves correctly. Neither proves the two work together on a phone. (3) They replace the service with a fake reply, so the real service was never asked. (4) Update the test to state the new rule, and the story it comes from.
