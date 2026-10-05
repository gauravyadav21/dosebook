# Review by a person

The roadmap asks that a person reads every diff. Only the participant can do this. This page is the sheet for it: what to open, where a mistake would matter most, and a place to sign. Nothing here is filled in by the AI agent.

How to read a commit: `git show <hash>` in the terminal, or open the commit on GitLab. The code tour (`docs/10-code-tour/`) explains each area first.

## Commits on main
| Commit | What | Look hardest at | Tour | Read on | Notes |
|---|---|---|---|---|---|
| `86c4814` | Skeleton, skills, CI | `.githooks/pre-commit`; the rules in `AGENTS.md` | | | |
| `b05883a` | Requirements | `what-we-do-and-dont.md`; the negative cases in each story | | | |
| `c356e0d` | Architecture docs | ADR 0002 (auth) and 0003 (reading and chat) | | | |
| `9dbdadb` | Backend foundation | `auth/password.ts`, `auth/auth.guard.ts`, `configure-app.ts`, `prisma/schema.prisma` | 1, 6 | | |
| `cfc7a15` | Upload, read, confirm, timeline | `documents/file-type.ts`, `prescriptions/prescriptions.service.ts` (the confirm transaction), `extraction/normalize.ts` | 2 | | |
| `1252b6f` | Feedback, allergies, doses | `doses/doses.logic.ts`, `medicines/medicines.controller.ts` | 3 | | |
| `73eaef9` | Notes, own reminders | `own-reminders/own-reminders.controller.ts` | 3 | | |
| `68b4999` | Chat and medicine lookup | `chat/chat.rules.ts` (`decide`, `guard`), `medicine-info/gemini-medicine-info.ts` (the prompt) | 4 | | |
| `fb3ba1c` | Doctor contacts | `doctors/doctor-match.ts`, `doctors/share-text.ts` | 6 | | |
| `20bf148` | App foundation | `api/api.dart`, `app/app_scope.dart`, `features/auth/require_sign_in.dart`, `reminders/reminder_plan.dart` | 1, 5 | | |
| `5836ea7` | App screens | `features/upload/review_screen.dart`, `features/chat/chat_screen.dart`, `widgets/common.dart` (`Loader`) | 2, 5 | | |
| `f9195f1` | AI workflow, QA, build record | `ai-failures.md`, `open-items.md`: are they true? | 7 | | |
| `86d48f6` | GitLab CI | `.gitlab-ci.yml` | | | |
| `aab01df` | Dark mode, intro | `app/theme.dart`, `features/intro/intro_screen.dart` | 1 | | |
| (this branch) | Review fixes, review script | `scripts/gemini-review.mjs` (what it sends), the `DOSAGE` patterns in `chat.rules.ts` | 4 | | |

## Decisions the AI agent made without asking
From `docs/08-build-log/decisions.md`, rows marked "AI default, not yet reviewed". Write yes, no, or change.

| Decision | Yes / no / change |
|---|---|
| Only the doctor's contact is shared; "not verified" line; doctors are never merged by name alone | |
| After sign-in the action the visitor asked for continues, except for a new account, which sees the acknowledgement first | |
| An expired session returns to the visitor tabs with a message, not to a sign-in screen | |
| The appearance choice belongs to the phone, not the account | |
| "Intro dismissed" is kept in memory only | |
| Logo and splash keep the brand colour in dark mode | |
| The intro does not replace the acknowledgement after sign-up | |
| The logo itself (open book with a capsule) | |

## Questions from the reviews
| Question | Answer |
|---|---|
| Gemini review, records-2 and records-3: should every write also carry `userId`, even after an ownership check, or is "check, then write by id" the stated rule? | |
| Gemini review, app-1: should a failed document download show the server's message? | |
| Emulator run: should the course length be pre-filled from what was read ("3 days")? | |
| The chat's dosage rule now also refuses "how do I take X" and "when do I take X". Is that the intended line? | |
