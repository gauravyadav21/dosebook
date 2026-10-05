# Build log

How DoseBook was built, in order. The product was called "Personal Medicine Memory" until 5 Oct 2026. Written on 4 Oct 2026 from the session record. Times are UTC (India is +5:30). The full raw record is kept locally in `.session-archive/` and is not in git.

Sources and limits:
- Two terminal sessions with an AI coding agent. Session 1 is reconstructed from its record, not from memory.
- An earlier idea chat on the web could not be opened from the terminal; only what was retyped is recorded.
- Nothing has been committed at the time of writing.

## Session 1: 3 Oct, 17:47 to 19:20

| Time | What was asked | What happened |
|---|---|---|
| 17:47 | Continue the hackathon mobile app chat | Two attempts failed: account credit was too low |
| 18:14 | Connect to the earlier hackathon chat | No local record of it; the web chat link could not be opened (browser extension not connected). The participant pointed to `~/Downloads/ROADMAP.md` instead |
| 18:20 | Produce idea + PRD + skeleton; idea to follow later | Skeleton built without an idea: repo, `AGENTS.md` and copies, four skills, stub docs, NestJS backend with `/health`, Swagger, validation and rate limit, Flutter app with one screen, CI workflow, gitleaks hook. Node 20 used because current NestJS needs it. Checked: backend build, 1 unit and 2 e2e tests, Flutter analyze, test and web build, gitleaks. One gitleaks hit was a placeholder token in scaffold boilerplate; the file was replaced |
| 18:27 | (commit prompt) | The participant declined the commit. Nothing has been committed since |
| 18:33 | The idea: upload prescriptions, build a history, suggest medicines taken before for small illnesses, take feedback. Extra ideas: document store, doctor report with charts, area-wide medicine popularity | Agent's advice: cut to one core journey and one polish feature; make the chat recall-only; add a human confirm step after extraction; park the doctor report and crowd features |
| 18:38 | Is the crowd feature only risky because the data is fake? | No: it stays risky with real data (promotion rules, health-data consent, re-identification of small groups, popularity is not effectiveness). Kept as a future-work slide |
| 18:42 | Polish feature | "What worked for me" chat chosen |
| 18:57 | Commit skeleton and PRD? | "Review PRD first." PRD, journeys and stories S1-S5 written for review |
| 18:59 | Use an Obsidian vault; create a deck | `docs/` set up as the vault (shared config, Home note, templates, daily notes) with a Markdown slide deck in `docs/07-slides/`. Not opened in Obsidian by the agent |
| 19:04 | More features: all documents in one place; "prescribe" from history; auto reminders from the confirmed prescription with double notification | Reminders folded into the core journey (S6). "Prescribe" changed to recall: the app never prescribes |
| 19:08 | Keep a document stating recall vs prescribe, usable for FAQ and privacy policy; send the user to a doctor when needed | `docs/01-requirements/what-we-do-and-dont.md` written |
| 19:09 | "We are making a user mode for medical things… making them more aware of the medicines" | Positioning line written and placed in PRD, README, deck, Home, scope document and the agent context files |
| 19:12 | Notes section for own medicines; manual reminders; keep stating doctor vs app; nothing that needs a doctor's training | Stories S7 and S8, journeys J0 and J5 |
| 19:18 | Connect to Figma and create the mobile design | Figma MCP server added by the participant; it needed sign-in and a restart, which ended the session |

## Session 2: 3 Oct 19:21 to 4 Oct (ongoing)

### Design (3 Oct, 19:21 to 19:50)
- Figma connected. Choices: new file, all journeys J0-J5, Material 3 with the indigo seed already in the Flutter skeleton.
- Built: variables (19 colours, spacing, radius), 7 text styles, 17 icons, 15 components, 14 screens. Checked by screenshot and an audit script.
- 19:35: doctor contacts feature requested. Choices: share card with others; in MVP; a Doctor tab on each prescription plus a Doctors screen; open all prescriptions from a card. Story S9 written; 5 more screens and 3 components added.
- 19:50: four more screens requested. Figma refused: the Starter plan's tool-call limit was reached. Those screens exist only in the app.

### Build (3 Oct 19:57 to 4 Oct 05:10)
- 19:57: "Complete the project… frontend and backend… local auth… test cases… review with the roadmap." Asked for a time and token estimate: 6-10 hours and several million tokens were quoted.
- 19:59: plan and checkpoints shown first. Decisions: no commits; monolith; chat needs no outside AI; reading a photo uses a free model (Gemini); mobile only, web later.
- Backend: local PostgreSQL 15 cluster by script (no Docker on the machine), Prisma 7 with the pg adapter, local accounts with scrypt and JWT, then one module per story. Tests written alongside. Two bugs caught by tests (missing nested object gave 500; plural matching in chat).
- Mistake: the migrations folder was deleted to regenerate it. Prisma refused an AI-run database reset; the agent did not override it, restored the migration, added a second one and moved to a fresh database.
- Mobile: API client, session, reminders planner, shared widgets, 23 screens. Two bugs caught by tests (file picker API changed in v13; a card overflowed at phone width).
- Docs: data model, ADRs 0002-0004, standards, QA, guardrails, workflow, failures log, roadmap status, READMEs, CI.
- Emulator: sign-in, first run, timeline, prescription tabs, Today, marking, chat checked by screenshot. The system file picker could not be driven by script.
- Result at 05:10: backend 143 unit + 158 e2e, mobile 57 tests.

### First hands-on use and changes (4 Oct, 16:32 to 17:30)
- 16:32: backend and app started for the participant. Mistake: the app was first installed on an emulator that was already running and turned out to be the day-job device. Removed again; a separate emulator is used since.
- 16:35 to 16:49: questions on where credentials are stored and how to open the database (see `questions-and-answers.md`).
- 17:05: seven changes requested after trying the app: password show/hide; profile page; measurements log (future); auto refresh everywhere (the Timeline had not updated after a confirm); chat without feedback input, with medicine lookup, declining everything else; AI for medicine search; notes as plain text.
- Built: profile (S10), open notes and own reminders moved to Today (S7), chat lookup and decline (S5), one shared refresh mechanism and the `add-screen` skill. Result: backend 191 + 208, mobile 73.

### Gemini key and lookup (4 Oct, 17:30 to 17:56)
- Getting a key: Google asked for a card, then project creation failed; the participant got a key shortly after.
- 17:47: lookup narrowed to two facts (usually prescribed for; how to keep it), dosage questions refused with "not recommended, please visit your doctor", result saved for reuse.
- First real call failed: the default model had been retired (404), then the newest model was overloaded (503, 429). Fixed with Google's `-latest` alias and a fallback model. Verified live: first lookup about 4 s, repeat 0.01 s from the database, a non-medicine declined.
- Result: backend 224 unit + 212 e2e, mobile 75 tests.

### Status and record (4 Oct, 17:56 onward)
- Progress against the roadmap reported (see `open-items.md`).
- This build log, the Q&A, decisions, runbook and playbook written.
- 5 Oct: renamed to **DoseBook** (it was "Personal Medicine Memory" until then, and earlier entries in this log describe it under that name). Changed: product name in docs, app label, Flutter package `dosebook`, application id `com.dosebook.app`, backend package, databases `dosebook_app` and `dosebook_test` (data copied; old databases left in place). The Figma file title could not be changed through the API. The top folder is renamed by the participant after the session.
- 5 Oct: the participant's observation that an AI-built project shows the developer's thinking recorded in `docs/09-playbook/developer-judgement.md`, with what the AI left out until told and two checklists.
- 5 Oct: code tour written in `docs/10-code-tour/`: a map of the codebase and seven tours (sign-in, upload to confirm, doses and reminders, chat, screen refresh, privacy, tests), each checked against the code.
- Tool-trials file prepared: purpose per free tool, four standard tasks with prompts, a record sheet. No free tool has been run yet.
- Commit plan written (story by story). Advice on standing out, learning with AI, and cost and tools saved to `docs/09-playbook/`, with actions for this project added to `open-items.md`.

### S11: browse before sign-in, sign-up, splash and logo (5 Oct, evening)
Asked for by the participant after using the app: a logo and splash; sign-in must not be the first screen; ask for sign-in only when an action needs to know the user (including medicine lookup); a separate sign-up screen; email verification as future scope.
- Plan shown first. Two questions answered: visitor tabs explain the feature with no sample data; a line about "proof of concept, not production-ready" is a reusable point, not a new document (saved in `docs/09-playbook/developer-judgement.md` and one line in the deck).
- Story `S11` written, then 20 widget tests, then the code. Backend untouched: every route already needed a token, so this is an app-only change.
- How it works: `_Root` always shows the tabs; each tab shows `GuestView` to a visitor and never builds its `Loader`; one function, `requireSignIn`, sits in front of every action that saves or loads personal data and continues the action after sign-in. See code tour 1.
- Logo drawn as one small SVG and reproduced in three places from the same numbers: Flutter (`AppLogo`), Android vector (icon and launch screen), and `docs/02-architecture/assets/`. No new package.
- Found on the device: the Android launch colour did not match the app's real primary colour (the Figma hex was an approximation), so start-up would have changed colour. Read the real value from the theme and used that.
- Figma: the call limit refused the one call that draws the logo sheet and three frames. Script saved for later.
- The Pixel emulator came up as `emulator-5554` this time, the serial the work emulator had before. Checked the device's own name (`Pixel_3a_API_32`) before installing; only the DoseBook package was touched.
- Result: mobile 90 tests, analyze clean, debug APK built and run on the Pixel emulator. Backend unchanged (224 unit + 212 e2e as before, not rerun).

### First commits (5 Oct, night)
- Remote added: GitLab. Author name and email set with `git config --local`, so no other repository on the Mac is affected.
- Twelve commits made story by story from `commit-plan.md`. The first five were verified by the participant one at a time; the rest were made in one run at the participant's instruction.
- Each commit was scanned by gitleaks in the pre-commit hook, and its diff was searched for a personal email address, home-folder paths and day-job names before committing.
- The push took four tries, all recorded in the runbook: no sign-in available to the AI agent's shell; the account password refused (GitLab wants an access token); then "rejected (fetch first)", because GitLab had created an "Initial commit" with a template README. The 12 commits were replayed on top of it, keeping our README, and pushed without force. Files unchanged by the replay (same tree hash before and after).
- The token is stored in the macOS Keychain for this repository only (`git config --local credential.helper osxkeychain`). It was never typed into the chat.
- GitLab CI file added on branch `ci/gitlab`, to be merged once its first pipeline is green. It could not be tried locally.

### S12: light and dark mode, intro pages (5 Oct, late)
Asked for by the participant: light and dark mode, and intro screens that show a new user what the app does. Four choices answered before building: keep the existing splash; follow the phone plus an in-app choice; intro on every start until sign-in; four pages, the last on what the app never does.
- First story done on a branch (`feature/s12-theme-intro`) so the GitLab pipeline runs before `main` changes.
- Appearance: one field on the session, saved on the phone. No screen needed changing, because no screen had a fixed colour; that was checked by a search before starting.
- The logo and splash would have turned pale in dark mode (the dark theme's primary colour is a light lavender). They now use fixed brand colours in both modes.
- Intro: four pages, shown by `_Root` until a flag held in memory is set. Page 4 reuses the acknowledgement's wording from one shared list, so the two cannot drift apart.
- Result: mobile 102 tests, analyze clean, debug APK built and run on the Pixel emulator. Backend untouched.

### Review by a second model, live read, device run (5 Oct, night)
The participant asked to finish "this week's" list in one go. What only a person can do was prepared, not done.
- S12 merged to `main` after the participant reported a green pipeline.
- **Second-model review:** a script sends the code in six batches to Gemini with the project's own review skills. 9 findings; each checked against the code; 2 real and fixed (dosage questions with no number; a planner crash on an unreadable time), 1 plainly wrong. All batches were answered by the lite fallback model.
- **Live read:** the three fake samples read by the live model under neutral names: 32 of 32 fields correct. Clean typed samples only.
- **Device run:** upload through the system file picker, confirm, Timeline, Today, Share and Call all worked on the Pixel emulator for the first time. The picker needs keyboard focus and Enter; it ignores scripted taps. One fault found and fixed: a misleading refusal when the medicine lookup timed out.
- **For the participant:** `docs/06-qa/human-review.md` lists every commit with where to look, the AI agent's unreviewed defaults, and four questions the reviews raised.
- Not done: trials of Copilot or other tools (they need the participant's accounts); the human read-through itself.
- Result: backend 241 unit + 213 end-to-end, mobile 103 tests.

## Size of the work, from the session record
Read from the raw files on 4 Oct; the second session is still open, so its numbers keep rising.

| | Session 1 | Session 2 (so far) |
|---|---|---|
| Messages typed by the participant | 16 | 29 |
| Multiple-choice answers given | 11 | 9 |
| Output tokens | about 45 thousand | about 500 thousand |
| Tokens written to cache | about 0.13 million | about 1.8 million |
| Tokens read from cache | about 5.8 million | about 97 million |

The record shows a cost of about 2.36 USD for session 1 at the point it was written. No cost figure is recorded for session 2.
