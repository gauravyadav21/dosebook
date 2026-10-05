# AI tool trials

A record of each AI tool tried on this project: what it was used for, what it did well, where it failed, and how the result was checked. The same four tasks are given to every tool so the results can be compared. Started 4 Oct 2026.

Rules for every trial: fake data only; no day-job material; no secrets in a prompt; the participant runs the tool and checks the result; nothing is recorded as tried until it has been run.

## Which tool for which purpose
Free allowances are as reported by web sources on 4 Oct 2026 (links at the end). They were not verified here and they change.

| Tool | Free allowance (reported) | Use it here for | Why |
|---|---|---|---|
| GitHub Copilot Free (VS Code, github.com) | 2,000 completions and 50 chat, agent or review requests a month; small models (GPT-5 mini, Claude Haiku 4.5) | Inline completion while making small changes by hand; a Copilot code review on each story commit | Completion supports learning by typing. A review by a different model is a scored step. 50 requests is tight: keep 12 for the 12 commits in `docs/08-build-log/commit-plan.md` |
| OpenCode with free Zen models | A rotating set of free models | One small feature, tests first; test generation | The roadmap's planned build tool; already installed on the Mac |
| Groq free tier (through OpenCode) | About 30 requests a minute and 1,000 a day on most models | Boilerplate, extra negative tests, doc drafts | Fast; small context |
| Google `agy` (successor to the Gemini CLI) | Reports say the free Gemini CLI login ended in June 2026 and the replacement has a small daily quota | Explaining a flow; reviewing a spec or a doc | The roadmap named Gemini CLI for define and design; that line is out of date |
| Gemini in AI Studio (web chat) | Free | Second opinion on a spec or an ADR | No setup |
| Claude Code | Paid | Used for the build so far | See the first sheet below |

## Setup
- **Copilot Free**: open the repo folder in VS Code. Install the extensions "GitHub Copilot", "Dart" and "Flutter". Sign in with a personal GitHub account and choose the free plan. Completions appear as you type; chat is in the side panel. For review: push a branch, open a pull request on github.com and request a review from Copilot. Watch the monthly count in the Copilot menu.
- **OpenCode**: run `opencode` in the repo root. `/models` lists and switches models; pick one marked free. It reads `AGENTS.md` by itself.
- **Groq**: create a free key at console.groq.com, add it to OpenCode's providers (it stays outside the repo), then choose a Groq model with `/models`.
- **`agy`**: run `agy` in the repo root and sign in with a personal Google account. It reads `GEMINI.md`.
- **AI Studio**: https://aistudio.google.com, paste the story or ADR text.

## The four trial tasks
Give each tool the same task, the same prompt and the same context files. Start a fresh chat for each.

### T1 Review
- Context: `docs/01-requirements/stories/S9-doctor-contacts.md`, `docs/03-standards/coding-standards.md`, `backend/src/doctors/`, `backend/test/doctors.e2e-spec.ts`.
- Prompt: "Review this code against the story and the coding standards. Report bugs, missing tests, missing validation or authorisation, and anything a user could be harmed by. Most serious first. Do not edit code."
- Judge: real findings; false findings; anything it missed that another tool found.

### T2 Tests
- Context: `docs/01-requirements/stories/S10-profile.md`, `backend/test/profile.e2e-spec.ts`, `backend/test/support/app.ts`.
- Prompt: "Write three more negative tests for this story that are not already covered. Follow the helpers and style of the existing file. Fake data only."
- Judge: do they run; do they pass or fail for the right reason; did it follow the helpers; did it duplicate an existing test.

### T3 Explain
- Context: `mobile/lib/features/upload/`, `mobile/lib/api/api.dart`, `backend/src/prescriptions/`, `backend/prisma/schema.prisma`.
- Prompt: "Explain, file by file, what happens from tapping 'Confirm and set reminders' in the app to the rows being saved in the database. Say why each step exists. Then list three things most likely to go wrong."
- Judge: check each statement against the code; count wrong ones; did it invent a file or function.

### T4 Small change, tests first
- Context: `AGENTS.md`, the `add-screen` skill, `mobile/lib/features/auth/sign_in_screen.dart`, `mobile/test/widget_test.dart`, `mobile/test/support/fake_backend.dart`.
- Prompt: "On the Create account form only, add a 'Confirm password' field. The two passwords must match before the server is called. Write the failing widget test first and show it failing, then the change. No new packages."
- Judge: was the test written first; do `flutter analyze` and `flutter test` pass; rules followed (no new package, phone width, existing wording); how many corrections were needed. Revert the change afterwards unless you want to keep it.

## Record sheet (copy one per trial)
```
### <date> · <tool> · <model> · <task T1-T4>
- Context given:
- Time taken:
- What it got right:
- What it got wrong:
- Corrections I had to make:
- Did it follow the project rules (fake data, no new dependency, standards)?
- How I checked the result:
- Would I use it for this kind of task again?
- Failures worth a row in ai-failures.md:
```

## Trials

### 3-4 Oct 2026 · Claude Code · Claude Opus · whole build (not one of T1-T4)
- Context given: `AGENTS.md`, roadmap, PRD, stories, standards, as they were written.
- Time taken: about 9 hours for the main build, plus about 1.5 hours of changes after first use.
- What it got right: all ten stories built with tests; tests caught four of its own bugs before the participant saw them; kept to the scope line; refused to override a database-reset guard.
- What it got wrong: 11 failures logged in `ai-failures.md`. The ones that matter most: a stale Timeline found by the participant, not by a test; a retired model name written from memory; an app installed on the wrong emulator; a migration folder deleted.
- Corrections the participant had to make: seven changes after the first hands-on use.
- Did it follow the project rules: yes for fake data, secrets and no commits. No for the per-story loop: tests were written with the code, not first, and no second model reviewed anything.
- How the result was checked: 224 unit, 212 end-to-end and 75 app tests run locally; some screens seen on the emulator; one live Gemini lookup. Human review of the diff is still owed.
- Use again for: planning, building against a clear spec, writing tests and docs.
- Cost: paid; long sessions are expensive (see `docs/09-playbook/cost-and-tools.md`).

(Add a sheet below for each new trial.)

### 5 Oct 2026 · Gemini API (free tier) · gemini-flash-lite-latest · T1 Review
- **How:** `node scripts/gemini-review.mjs`. Six batches of source files (backend by area, and the app's client, session and sign-in code), each with the project's `review-diff` and `security-check` skills, the coding standards and the stories' acceptance criteria. Asked for JSON findings with file and line.
- **Result:** 9 findings in about a minute. After checking each against the code: 2 real and fixed, 1 real and left, 1 plainly wrong, 2 fair but not exploitable, 3 not faults. Full text and triage: `docs/04-ai/reviews/2026-10-05-gemini-review.md`.
- **Good:** found a real gap in the chat's dosage rule that 224 unit tests had not (questions like "how do I take it" with no number). Fast, free, and easy to rerun. Returning JSON with file and line made the triage quick.
- **Bad:** one finding quoted a line that does not exist and reported a missing check that is there. Two findings argued with themselves and ended as "verify that...". It reported nothing at all for auth, upload and confirm, which is more likely shallow reading than clean code.
- **Limits met:** the first-choice model did not answer, so every batch was reviewed by the lite fallback. The free tier may train on what is sent, so only our own code with fake data went.
- **Lesson:** a second model is worth having as a source of leads, not as a verdict. Every finding has to be checked against the code by someone who can read it.
- **To compare like for like:** paste the same prompt (printed by the script's `prompt()` function) and the same files into another tool, and fill a sheet below.

## Summary: pros and cons per tool
Fill a row only after at least one trial. Empty means not tried.

| Tool and model | Tasks tried | Good at | Weak at | Would use for |
|---|---|---|---|---|
| Claude Code (Opus) | Whole build | Following a written spec; tests; keeping to safety rules; saying what it did not verify | Facts from memory (model names, plugin APIs); skipped tests-first and review when run unattended; costly in long sessions | Planning, building, docs |
| Copilot Free | | | | |
| OpenCode + free Zen model | | | | |
| Groq (via OpenCode) | | | | |
| `agy` / Gemini | | | | |
| Gemini in AI Studio | | | | |

## Sources for the reported allowances (4 Oct 2026)
- Copilot Free: https://www.itechguides.com/github-copilot-free-explained-limits-features-setup-and-privacy/ and https://costbench.com/software/ai-coding-assistants/github-copilot/free-plan/
- Gemini CLI change: https://www.tembo.io/blog/gemini-cli-pricing and https://geminicli.com/docs/resources/quota-and-pricing/
- OpenCode Zen free models: https://www.maximalstudio.in/blog/opencode-zen-free-models
- Groq free tier: https://tokenmix.ai/blog/groq-free-tier-limits-2026
