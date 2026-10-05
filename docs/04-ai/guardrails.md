# Guardrails

Two kinds: rules for how AI tools are used to build the project, and rules the product enforces on itself.

## Building with AI tools
See `AGENTS.md` for the full rules. In short:
- **Secrets**: none in the repo. `gitleaks` runs in the pre-commit hook and in CI. `.env` is ignored; `.env.example` holds names only.
- **Fake data only**: sample prescriptions in `samples/`, test users and doctors are invented. Free AI tiers may train on what they are sent.
- **No client material**: nothing from day-job projects goes into prompts or the repo.
- **Dependencies are vetted** before they are added. Added so far, all first-party or widely used: `@nestjs/jwt`, `@prisma/adapter-pg`, `pg`; `shared_preferences`, `file_picker`, `url_launcher`, `share_plus`, `flutter_local_notifications`, `timezone`.
- **A person reads every diff** before it is committed, and says what was tested.
- **Destructive commands need a person**: when a tool asks for a database reset or similar, the agent stops and asks. See the second entry in `ai-failures.md`.
- **Failures are logged** in `ai-failures.md` with the rule that changed.

## In the product
Wording and scope: `docs/01-requirements/what-we-do-and-dont.md`. Enforced in code:

| Rule | Where | Test |
|---|---|---|
| Extraction output is never saved without Confirm | `prescriptions.service.ts` | `prescriptions.e2e-spec.ts` |
| Model output is cleaned before the user sees it | `extraction/normalize.ts` | `extraction.spec.ts` |
| Chat lists only medicines in the user's own history | `chat.rules.ts` (`answer`, `guard`) | `chat.rules.spec.ts`, `chat.e2e-spec.ts` |
| Red-flag and out-of-scope messages get the fixed escalation and no medicines | `chat.rules.ts` (`classify`) | same |
| Allergies and "did not work" / "side effect" block recall | `chat.rules.ts` (`isBlocked`) | same |
| Every answer carries a source label and the doctor-vs-app line | `chat.rules.ts` (`guard`) | same |
| Own reminders are never shown as prescribed; their dose is never corrected | `own-reminders.controller.ts`, mobile `SourceTag` | `notes.e2e-spec.ts`, `widget_test.dart` |
| Chat declines anything that is not symptom recall or a medicine lookup | `chat.rules.ts` (`decide`) | `chat.rules.spec.ts`, `chat.e2e-spec.ts` |
| Chat never asks for feedback; it shows what is recorded | mobile `chat_screen.dart` | `widget_test.dart` |
| A dosage question is refused with "not recommended, please visit your doctor" and never reaches the model | `chat.rules.ts` (`asksDosage`) | `chat.rules.spec.ts`, `chat.e2e-spec.ts` |
| Only the medicine name goes to the model; only "usually prescribed for" and "how to keep it" are read back, cleaned of doses and instructions, saved once, and always shown with a "not advice" line | `medicine-info/` | `medicine-info.spec.ts`, `chat.e2e-spec.ts` |
| Profile details and notes are stored only; chat does not read them | `me.controller.ts`, `notes.controller.ts` | `profile.e2e-spec.ts`, `notes.e2e-spec.ts` |
| Reminders come only from confirmed schedules or the user's own reminders | `doses.controller.ts` | `doses.e2e-spec.ts` |
| Doctor details are shown as printed and marked "not verified" | mobile `DoctorDetails` | `widget_test.dart` |
| Sharing a doctor sends the contact only | `doctors/share-text.ts` | `doctors.e2e-spec.ts` |
| First-run acknowledgement before the app can be used | `me.controller.ts`, mobile `_Root` | `auth.e2e-spec.ts`, `widget_test.dart` |
| A user can reach only their own data | every query filters by user id | "another user" cases in every e2e file |

## Open
- The chat keyword lists and the escalation wording have had no medical or legal review.
- AI-written medicine descriptions have had no medical review.
- The free Gemini tier is acceptable only while all uploads are fake.
