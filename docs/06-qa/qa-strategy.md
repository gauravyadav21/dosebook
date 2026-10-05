# QA strategy

Status on 2026-10-04. Numbers are from the last local run and will drift; rerun to check.

## What runs
| Suite | Command | Count | Against |
|---|---|---|---|
| Backend unit | `npm test` | 224 | Pure logic, mocked HTTP |
| Backend end-to-end | `npm run test:e2e` | 212 | Real application pipeline and a real local PostgreSQL |
| Mobile | `flutter test` | 90 | Widgets with an in-memory fake server; pure logic |
| Static | `npm run lint`, `npm run build`, `flutter analyze` | | |

## How tests map to stories
One end-to-end file per story group in `backend/test/`, named for it: `auth`, `documents` (S1, S2), `prescriptions` (S2, S3), `feedback-allergies` (S4), `chat` (S5, S8), `doses` (S6), `notes` (S7: open notes and own reminders), `doctors` (S9), `profile` (S10). Each acceptance criterion in `docs/01-requirements/stories/` has at least one test whose name restates it.

## Negative tests
Every story group covers: bad input (400), no token and expired token (401), and another user's record (404). Also: oversize and wrong-type files, a file whose name lies about its type, confirming twice, a schedule that is incomplete or out of range, marking a dose that is not scheduled, an extractor that throws, and repeated login attempts (429).

## Safety rules under test
- Chat: no medicine on red-flag, out-of-scope, long-lasting or worsening messages; no medicine outside the user's history; blocked medicines never recalled; source label and doctor-vs-app line on every answer. The `guard` function has its own tests with deliberately broken answers.
- Nothing from an upload reaches the timeline, Today or doctor cards before Confirm.
- Own reminders are labelled as the user's own in Today; their dose is stored exactly as typed.
- Chat declines everything except symptom recall and medicine lookup, and never asks for feedback.
- Medicine lookup: only the name reaches the model; the saved description has no dose or instruction; a second lookup makes no model call.
- Screens refresh without navigation when data changes, on pull, and on app resume.
- Sharing a doctor card contains no condition or medicine.

## Techniques and how each was validated
| Technique | Used for | Human validation |
|---|---|---|
| Test generation from acceptance criteria | All end-to-end files | **Owed.** The author of the code also wrote the tests in the same session. A person still has to read each test against its story and confirm it checks the right thing |
| Tests first | Not followed in this pass. Code and tests were written together | Record as a deviation from the per-story loop |
| Edge-case discovery | Date maths (month ends, leap days), schedule limits, name matching | Owed: review the case lists in `doses.logic.spec.ts`, `doctors.logic.spec.ts`, `chat.rules.spec.ts` |
| Negative testing | See above | Owed |
| AI-assisted debugging | Failures found by the tests are logged in `docs/04-ai/ai-failures.md` | Each entry names the test that caught it |
| Cross-model review | **Not done.** The diff has not been reviewed by a second model | Planned: Copilot's review on each story's pull request, and trial task T1 in `docs/04-ai/tool-trials.md`. Record each finding and what was done about it |

## Manual run on the Android emulator (4 Oct 2026)
Debug build installed on a Pixel 3a (API 32) emulator against the local backend. Checked by screenshot: sign-in, first-run acknowledgement, empty Today, Timeline with a confirmed prescription, both prescription tabs, Today with prescribed and own-reminder doses, marking a dose taken, chat recall.

Not completed in that run: choosing a file in the system file picker (scripted taps on the file were ignored, so the upload, review and schedule screens were not reached on the device; the prescription was created through the API instead). Those screens are covered by widget tests only. Call, Share, notes editing, allergies, doctor edit and delete were not exercised on the device either.

## Not tested
- Reading a prescription with the live Gemini service: only a mocked response so far.
- The live medicine lookup was run once (ibuprofen, 4 Oct 2026). The saved text has not been reviewed by anyone qualified, and only one medicine has been tried.
- Notifications firing on a device at the right time. Only the planning logic.
- iOS, a real phone, and the web build.
- Extraction accuracy on a test set: there is no real extraction to measure yet. The PRD success criterion on accuracy is open.
- Load, and behaviour with a slow or dropping network beyond the "could not reach the server" path.
- GitHub Actions has not run this code.

## S11 (5 Oct 2026): browse before sign-in, sign-up, splash
- Tests were written before the screens: 20 widget tests in the group "Browse before sign-in, sign-in, sign-up and first run (S8, S11)". First run: the test file did not compile, because `sign_up_screen.dart`, `logo.dart` and the `tagline` wording did not exist yet. After the code was written all passed on the first run, which is weaker evidence than seeing each one fail on an assertion.
- Run on the Pixel emulator by the AI agent: Android launch screen with the logo, visitor Today, Create account with a fake address, "Passwords do not match", account created, acknowledgement, Today, Sign out back to the visitor view, Upload as a visitor opening Sign in, launcher icon and name.
- Not run on the device: continuing to the asked-for action after sign-in, chat as a visitor, the expired-session message (widget tests only). The Flutter splash was not caught in a screenshot; the Android launch screen was.
- Not yet validated by the participant.
