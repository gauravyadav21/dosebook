# Questions asked during the build, and the answers

Every question the participant asked across both sessions, grouped by topic, with the answer as it stands now. Where a first answer turned out wrong, the corrected answer is given and the correction is noted. Written 4 Oct 2026.

## Idea and scope

**Is my idea good, and what else could I add? (history from prescriptions, chat that suggests medicines taken before, feedback, doctor report, area-wide medicine popularity)**
The core is good. Cut it to one user, one core journey (upload, AI reads, user confirms, timeline) and one polish feature. Make the chat recall-only: it shows only what is already in the user's own history. Add a confirm step after extraction. Park the doctor report and the crowd feature as future work.

**Is the crowd/area medicine feature risky only because the data is fake? With real data there is no risk, right?**
No. It stays risky with real data: promoting medicines is regulated, health data needs consent, small groups can be re-identified, and popular does not mean effective. It stays a future-work slide, described as aggregated, opt-in, non-promotional and subject to legal review.

**Can the app prescribe a medicine from the history?**
No. Only a doctor prescribes. The app recalls: "you took X for this before, prescribed by Dr. Y". This wording is fixed in `docs/01-requirements/what-we-do-and-dont.md`.

**Can it set automatic reminders from the prescription?**
Yes. The user confirms the schedule once (times of day, before or after food, course length). Reminders come only from confirmed data. One alert at dose time and one follow-up if not marked.

**Should chat include medicines the user added themselves?**
First answer: yes, labelled "you noted this yourself". Current answer: no. Since 4 Oct notes are plain text and own reminders carry no symptom, so chat uses confirmed prescriptions only.

**Why does the chat "have no API"? Do we need one?**
The chat needs no outside AI service. It answers from saved data with fixed rules. The only step that needs a model is reading a prescription photo, and, since 4 Oct, fetching a short description of a medicine the first time it is looked up.

## Design

**Can you connect to Figma and create the design?**
Yes, through the Figma MCP server (`claude mcp add --transport http figma https://mcp.figma.com/mcp`, then `/mcp` to sign in, then restart). File: see `docs/02-architecture/design.md`.

**Figma MCP is not showing.**
It was registered but not signed in. An unauthenticated server exposes no tools. Run `/mcp`, choose figma, authenticate. It is registered per folder unless added with `--scope user`.

**Design a splash screen and a logo in Figma.** (5 Oct 2026)
The logo and splash are built in the app and on Android. Figma refused the call (Starter plan limit), so the Figma side is a saved script, `docs/02-architecture/assets/figma-s11-frames.js`, to run when the limit resets. See the Logo section of `docs/02-architecture/design.md`.

**The login screen should not be the first screen.** (5 Oct 2026)
Done as story S11. The app opens on the tabs. Sign-in appears when the visitor taps Sign in, or starts upload, a reminder, a note, the doctors list or a chat question. No server change was needed.

**Do we need a sign-up screen?** (5 Oct 2026)
Yes, now separate from sign-in: email, password, password again. The email is not verified; that is future scope in the PRD.

**Add light and dark mode, and intro screens.** (5 Oct 2026)
Done as story S12. Appearance is in the account menu (System, Light, Dark) and is saved on the phone. The intro is four pages after the splash, shown on every start until sign-in, and can be reopened from "About DoseBook" in the account menu. No backend change, no new package.

**Design the missing screens too.**
Not possible that day: the Figma Starter plan's tool-call limit was reached (also: 3 pages per file). The four screens were built in the app without frames.

## Time, cost, progress

**How long will it take to build everything, and how many tokens?**
Estimate given: 6-10 hours and several million tokens. Actual, from the session record: the main build ran about 9 hours of session time; see the table at the end of `build-log.md` for token counts.

**How much of the roadmap is done and how much remains?**
See `open-items.md`. In short: the product is built and tested locally; nothing was committed at that point (committed on 5 Oct 2026, see `commit-plan.md`), reviewed by a person or a second model, deployed, or packaged.

## Running it

**Start the backend and run the app on the emulator.**
See `runbook.md`. Use the Pixel 3a emulator, not the day-job emulator.

**`cd backend && nvm use 20 && npx prisma studio` failed with "no such file or directory: backend".**
The shell was already inside `backend/`. Run `nvm use 20 && npx prisma studio` there. Studio keeps running and prints a local address; the "timeout" message only means it moved to the background.

## Credentials and database

**Where are the credentials saved?**
Accounts: the `User` table in the local PostgreSQL database `dosebook_app`. The password is stored only as a salted scrypt hash. On the phone: only the session token, in app preferences, removed on sign-out. Backend secrets: `backend/.env`, which is gitignored.

**How can I access the database?**
Host `localhost`, port `54329`, database `dosebook_app`, user `app`, no password. With psql, pgAdmin 4 or Prisma Studio. Details in `runbook.md`.

**pgAdmin asks for a master password.**
That is pgAdmin's own password for protecting saved server passwords, not the database's. Enter the one set earlier, set a new one, or use "Reset Master Password" (this clears pgAdmin's saved passwords only).

**It now asks for a password to connect to "PostgreSQL 15".**
That is a different server: the system-wide install on port 5432, user `postgres`. The app does not use it. Cancel, and register a new server with the values above.

**How do I query and see entries in the user table?**
In pgAdmin: Tables → User → View/Edit Data → All Rows, or `select id, email, "createdAt" from "User";`. Table and column names with capitals need double quotes.

## Gemini

**Is there a free model, maybe from Firebase, to read the photo?**
Yes: Gemini Flash on the free tier. It is called from the backend, not through Firebase, so the key stays on the server. On the free tier Google may use submitted data, so fake prescriptions only.

**How do I add the Gemini API key?**
Create it at https://aistudio.google.com/apikey, add `GEMINI_API_KEY=...` to `backend/.env`, restart the backend. Never paste the key into a chat.

**I cannot get a key without a GCP project that needs card details.**
The free key comes from AI Studio, not the Cloud Console. Use a personal Gmail, choose "Create project" inside the AI Studio dialog, and do not enable billing. In the EEA, UK and Switzerland the free tier needs billing.

**"Failed to create project. Please try again later."**
A Google-side error. Try: pick an existing project in the dialog; or create the project at console.cloud.google.com/projectcreate (no card needed) and select it; or another personal account; or wait. The participant obtained a key shortly afterwards.

**Which model name?** (correction)
First answer: `gemini-2.5-flash`. That was wrong for a new key: the model had been retired and returned 404. Current: `gemini-flash-latest` with `gemini-flash-lite-latest` as fallback, both changeable in `backend/.env`.

**What should the medicine lookup return?**
Only what the medicine is usually prescribed for and how to keep it. Dosage questions get "not recommended, please visit your doctor". Each medicine is fetched once and then served from the database.

## Standing out, learning and cost

**Should I commit story by story?**
Yes. The plan is in `commit-plan.md`: 12 commits in order, each with its files and the check to run first. Start with `git reset`, because files from the first session are still staged.

**Everyone will use AI tools and my project feels limited. Should I add something to stand out?**
Not features. The scoring rewards how AI was used and engineering quality far more than size. Stand out with proof: measured accuracy, safety shown on purpose, a real failures log, visible human review and story-sized commits, one own skill shown running. At most one fitting addition, after review and commits. Full list: `docs/09-playbook/standing-out.md`; actions for this project: `open-items.md`.

**How can I use AI in coding and design while understanding what is built, and guide it to code well? Paid tools are expensive and free ones are unreliable.**
Make the AI teach: tours of one flow, read tests first, change something small yourself, question every diff, explain it back. Guide it with what is written down: a spec per feature, ADRs, standing rules, plan first. See `docs/09-playbook/learning-with-ai.md`. On cost: the expense is long sessions re-reading themselves; use one session per phase, batch changes, a strong model for plan and review and a cheaper one for routine work. Trial any free tool on one small story and judge it by the tests. See `docs/09-playbook/cost-and-tools.md`.

**Which free AI tools can I use in this project, for what, and how do I record their pros and cons?**
Copilot Free for inline completion while changing code by hand and for a review of each story commit (50 chat or review requests a month, so budget them). OpenCode with a free model for one small feature, tests first. Groq for boilerplate and extra tests. Google's `agy` or AI Studio for explaining a flow or checking a spec. Give every tool the same four tasks (review, tests, explain, small change) and fill one record sheet per trial in `docs/04-ai/tool-trials.md`; failures also go to `ai-failures.md` with the tool named. The agent cannot run these tools; the participant does.

**Can you write a code tour for this project?**
Yes: `docs/10-code-tour/`. Start with its README, then follow the reading order. Each tour follows one action through every file, names the test that proves each rule, lists the agent's unreviewed choices, and ends with things to try and questions with answers.

**If the AI does the work, can't anyone build this? Where does the developer matter?** (participant's observation, 5 Oct)
No. The project shows the developer's thinking: the scope, the constraints and the workflow. With weaker thinking things still work but fall short across the whole project. In this build the safety line, several features and the refresh rule came from the participant, and the AI left out tests-first, review, the real-service check and the between-screens fault until told. Written up with checklists in `docs/09-playbook/developer-judgement.md`.

**What is the project called?**
DoseBook, since 5 Oct 2026. Before that the working name was "Personal Medicine Memory". In code: Flutter package `dosebook`, application id `com.dosebook.app`, databases `dosebook_app` and `dosebook_test`.

**Why did `git push` fail, and what fixed it?** (5 Oct 2026)
Three different causes, in order. (1) "could not read Username": the command was run where no prompt can appear (the AI agent's shell, and the `!` prefix); run it in Terminal.app. (2) "HTTP Basic: Access denied": GitLab does not accept the account password for git; use a personal access token with `write_repository` as the password. (3) "rejected (fetch first)": the project was created on GitLab with a README, so the remote already had a commit; fetch, replay the local commits on top (`git rebase origin/main`) and push. Never force-push to fix this without looking at what is on the remote first.

**Can the AI agent push?** (5 Oct 2026)
Only after the participant has signed in once from Terminal with the Keychain helper set for this repo. The token is never given to the agent.

**Which of "this week's" tasks could the AI agent do, and which not?** (5 Oct 2026)
Done by the agent: a review by a second model (Gemini, scripted), a live read of the fake samples, an end-to-end run on the emulator, and the fixes that came out of them. Prepared but not done: the human read-through (`docs/06-qa/human-review.md`). Not possible for the agent: trials of Copilot and other tools in the participant's own accounts.

**How do I rerun the second-model review?** (5 Oct 2026)
`node scripts/gemini-review.mjs` from the repo root with Node 20, or name batches: `node scripts/gemini-review.mjs chat app`. It writes `docs/04-ai/reviews/<date>-gemini-review.md`. Add the triage by hand underneath.

## Record keeping

**Are you saving all details of how this was built?**
Before this file: decisions, architecture, failures and status were in `docs/`, but not the questions, the story or a reusable guide. Now: `docs/08-build-log/` (this folder), `docs/09-playbook/`, and the full raw record in `.session-archive/` (local only).
