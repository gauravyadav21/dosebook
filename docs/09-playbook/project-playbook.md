# Project playbook

For starting the next project of this kind (a mobile app with a backend, built with an AI coding agent). Copy this folder into the new repo and give this file to the agent as its first context. It records the answers already given once, the order that worked, and the mistakes not to repeat. Written from the DoseBook build, 3-4 Oct 2026.

How to use it: the agent reads sections 1 and 2, asks only the questions in section 3, then follows sections 4 to 8.

Read also, in this folder:
- `developer-judgement.md`: the developer's thinking is the product; what the AI leaves out unless told; checklists before and after handing it a task.
- `standing-out.md`: how to differ when every team uses AI (proof of quality, judgement and ownership; no extra features).
- `learning-with-ai.md`: how the participant learns from what is built, prompts to reuse, system design topics, a review checklist.
- `cost-and-tools.md`: where the cost goes, session habits, how to trial a tool, free-tier limits.
- `roadmap-template.md` and `docs-template.md`.

## 1. Standing answers (do not ask these again)
These were decided by the participant and hold unless they say otherwise.

| Topic | Answer |
|---|---|
| Commits | Never commit without being asked. Before any commit, say what was tested, by whom and how. If it could not be tested, ask first. Commit story by story, from a written commit plan, never as one large commit |
| Learning | The participant wants to understand the code, not only receive it. Explain while building, offer a tour of each flow, and say which decisions were the agent's own |
| Attribution | No AI-tool attribution in commits, PRs or docs |
| Day-job material | None in the repo, prompts or screenshots. Do not touch day-job devices or emulators; check the device and use an explicit serial |
| Data | Fake data only. Fake names, numbers and documents, clearly marked |
| Secrets | In `.env`, gitignored; `.env.example` holds names only. Never ask for a key in chat; the participant edits the file |
| Backend shape | One application (monolith) with a folder per feature |
| Platform | Mobile first (Android emulator). Web later, only when asked |
| Cost | Free tiers only. No card, no paid service without asking |
| AI inside the product | Behind an interface, called from the backend, output treated as untrusted and cleaned, result saved so it is fetched once. The product never advises; anything needing a professional is refused or redirected with fixed wording |
| Screens | Every screen refreshes itself: on data change, on pull, on app resume |
| Docs | Plain language. Requirements, architecture, standards, AI workflow, delivery, QA, build log. Obsidian vault inside `docs/` |
| Record | Keep a build log, a Q&A file and a decisions table as the work goes, not at the end |
| Scope | One user, one core journey, one polish feature. New ideas go to "future scope" unless the participant says build |
| Unattended work | Allowed. Show the plan and checkpoints first; stop at a checkpoint if its tests fail |

## 2. How the participant works
- Ideas arrive in short messages, often several at once, sometimes with speech-to-text slips ("subscription" for prescription). Restate the idea in one line before acting on an unclear word.
- They decide quickly when given two or three concrete options with a recommendation. Use that instead of open questions.
- They try the app by hand and report what feels wrong. Expect a round of changes after the first run.
- They want to see a plan before large work, and a clear list of what was and was not verified after it.

## 3. Questions to ask at the start (only these)
1. The idea in two sentences: who is the one user, what is the one journey, what is the one extra.
2. What must the product never do (the scope line)? Write it down as a "do / do not" page on day one.
3. Is there anything regulated or sensitive (health, money, children, personal data)? If yes, add fixed refusal wording and a "not advice" rule now.
4. Does any feature need an outside service or AI? Which free option, and who creates the key?
5. Deadline and what is submitted or scored.
6. Design: is there a design tool and plan limit to work within? (Figma Starter: 3 pages per file and a low daily call limit.)

Everything else: use section 1.

## 4. Order of work that held up
| Step | Output | Closed when |
|---|---|---|
| 1. Idea and scope | PRD, journeys, one story file per feature with acceptance criteria and negative cases, the "do / do not" page | Participant has read them |
| 2. Decisions in one round | Stack, auth, data shape, where AI is used, platform, commit rule | All answered before any code |
| 3. Design | Tokens, components, one frame per screen | Screenshots checked; frame-to-story table written |
| 4. Backend, story by story | Schema and migration, module, validation, tests | Lint, build, unit and end-to-end tests green |
| 5. App | Client, session, shared widgets, screens, tests | Analyze and tests green; debug build runs on the emulator |
| 6. Real-service check | Every outside call run once for real | Result recorded |
| 7. Hands-on round | Participant uses it; changes collected in one list | Changes built and re-tested |
| 8. Docs and record | Data model, ADRs, QA, failures log, build log, open items | Counts and status match reality |
| 9. Review and commit | Human reads the diff; second model reviews; commits per story | CI green |
| 10. Deploy, package, submit | Hosted backend, build for judges, video, ZIP | Checklist complete |

Backend before app before docs worked: at any point the finished part was usable.

What should be done differently next time: tests before code per story, review and commit after each story rather than at the end, and a real-service call as soon as the key exists.

## 5. Stack recipe (versions that worked, and the non-obvious steps)
- **Node 20.19+** (`nvm use 20`). Prisma 7 refuses Node 18.
- **NestJS 12**, ESM (`"type": "module"`, imports end in `.js`).
- **Prisma 7**: generator `prisma-client` with output inside `src/` (so the build includes it), `moduleFormat = "esm"`, `importFileExtension = "js"`. Needs a driver adapter: `@prisma/adapter-pg` + `pg`. `migrate dev` does not generate the client; run `prisma generate` (also as `postinstall`).
- **PostgreSQL without Docker**: `backend/scripts/dev-db.sh` starts a throwaway cluster from an installed PostgreSQL on its own port with trust auth on localhost.
- **Vitest 4 with NestJS**: decorator metadata works out of the box. End-to-end tests boot the real app with supertest against a real test database; each test registers its own user, so files run in parallel with no cleanup. A `globalSetup` runs `prisma migrate deploy`.
- **Rate limits** read from the environment so tests can raise them.
- **Flutter 3.38 / Dart 3.10**. Packages used: `http`, `shared_preferences`, `file_picker`, `url_launcher`, `share_plus`, `flutter_local_notifications`, `timezone`.
- **Android setup**: core library desugaring for notifications; `INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`; the two notification receivers; a `tel` query for the dialler; cleartext HTTP allowed in the debug manifest only; emulator reaches the Mac at `10.0.2.2`.

## 6. Patterns to copy
| Pattern | Copy from |
|---|---|
| Every query filtered by the signed-in user; another user's record is 404 | any controller, e.g. `backend/src/doctors/doctors.controller.ts` |
| Global auth guard with a `@Public()` marker | `backend/src/auth/` |
| DTO validation, unknown fields rejected, nested objects required | `backend/src/prescriptions/prescriptions.dto.ts` |
| Business rules as pure functions with unit tests beside them | `backend/src/chat/chat.rules.ts`, `backend/src/doses/doses.logic.ts` |
| A final server-side guard on anything shown to the user | `guard` in `chat.rules.ts` |
| Outside AI behind an interface, with a cleaner, a saved result and a fallback model | `backend/src/common/gemini.ts`, `backend/src/medicine-info/` |
| A stand-in for the AI when there is no key | `backend/src/extraction/demo.extractor.ts` |
| File upload: type from content, random stored name, owner-checked download | `backend/src/documents/` |
| End-to-end test helpers | `backend/test/support/app.ts` |
| One `Loader` that gives every screen refresh-on-change, pull and resume | `mobile/lib/widgets/common.dart`, `mobile/lib/app/app_scope.dart` |
| Phone features behind replaceable functions for tests | `mobile/lib/app/platform.dart` |
| Fixed wording in one file per side | `mobile/lib/app/wording.dart` |
| Widget tests with an in-memory fake server at phone width | `mobile/test/support/fake_backend.dart` |
| Skills for the agent | `.claude/skills/` (`spec-story`, `write-tests`, `add-screen`, `review-diff`, `security-check`) |

## 7. Mistakes made here: do and do not
- Do run every outside-service call once for real before calling it done. Mocked tests hid a retired model name and an overloaded model.
- Do list what a key can use before choosing a model name. Prefer the provider's "latest" alias and keep a fallback.
- Do read the installed package's source before using a plugin API from memory.
- Do add `@IsDefined()` next to `@ValidateNested()`.
- Do run widget tests at phone width; it caught an overflow.
- Do put refresh in one shared place; per-screen refresh after navigation went stale.
- Do check which device is attached before installing an app, and pass its serial.
- Do treat a tool's refusal to run a destructive step as final; find another way.
- Do not edit or delete an applied migration.
- Do not write a weekday or other fact from memory when it can be computed.
- Do not rely on `$VAR:text` in zsh; write `${VAR}:text`.
- Do not spend the design tool's daily call limit on many small calls.
- Do not leave "tests first", "second-model review" and "commit per story" to the end; they are the scored evidence.

## 8. Keeping time and tokens down
- Settle all decisions in one question round before building (section 3). Each later change of direction re-reads the whole conversation.
- Give the agent this file, the PRD and the stories first. It then needs no exploration.
- Ask for one plan with checkpoints, approve it, and let it run. Interruptions mid-build cost more than a wrong default fixed later.
- Batch: one message with all changes after a hands-on round, as on 4 Oct, is cheaper than one change per message.
- Keep answers to recurring questions in `docs/08-build-log/questions-and-answers.md` and `runbook.md`; point to them instead of asking again.
- Long sessions are expensive mostly because of re-reading: in this build, tokens read back from cache were about two hundred times the tokens written as output. Start a fresh session for a new phase, with the build log and open items as its context.
- Let tests, not screenshots, carry verification. Use the emulator only for what tests cannot show.
