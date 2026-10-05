# Document set to create on day one

Create these files empty on the first day and fill them as the work goes. Each line says what the file must contain. Paths are relative to `docs/`.

| File | Must contain |
|---|---|
| `Home.md` | Index of every doc; conventions |
| `ROADMAP.md` | Dates, scoring, stack, phases, rules, checklist; a status table at the top that is kept current |
| `01-requirements/prd.md` | Problem, the one user, core journey, polish feature, guardrails, out of scope, success criteria |
| `01-requirements/user-journeys.md` | One short paragraph per journey |
| `01-requirements/stories/S<n>-<name>.md` | "As a… I…", acceptance criteria as Given/When/Then, negative cases (bad input, no or expired token, another user's data) |
| `01-requirements/what-we-do-and-dont.md` | The scope line as a do / do-not table, fixed refusal wording, FAQ, privacy statements. Single source for in-app wording |
| `02-architecture/data-model.md` | Table of models, ownership rule, choices and why |
| `02-architecture/openapi.json` | Generated from the running backend, not written by hand |
| `02-architecture/adr/000n-<topic>.md` | Context, decision, trade-offs. One each for stack, auth, where AI is used, storage |
| `02-architecture/design.md` | Design file link, frame-to-story table, components, tokens, what is not designed |
| `03-standards/coding-standards.md` | Rules for both sides, including the ones that came from failures |
| `04-ai/ai-workflow.md` | Context given to the agent, where AI was used and where a person checked, deviations from the loop |
| `04-ai/guardrails.md` | Rules for using AI tools; rules the product enforces, each with file and test |
| `04-ai/ai-failures.md` | One row per real failure: what went wrong, cause, rule that changed |
| `05-delivery/env-vars.md` | Names only, with purpose and defaults |
| `06-qa/qa-strategy.md` | Suites and counts, story-to-test map, negative tests, how a person validated each technique, what is not tested |
| `07-slides/` | Pitch deck |
| `08-build-log/build-log.md` | What was asked, decided, built and checked, in order |
| `08-build-log/questions-and-answers.md` | Every question asked and its current answer |
| `08-build-log/decisions.md` | Every decision, who took it, why |
| `08-build-log/runbook.md` | Start, stop, inspect, fix; troubleshooting table |
| `08-build-log/open-items.md` | Everything not done or not verified |
| `09-playbook/` | This folder, carried to the next project |

Outside `docs/`:
- `AGENTS.md` (with identical copies for each agent tool): idea, stack, per-story loop, rules, what to read first.
- `.claude/skills/`: one skill per repeated task.
- `README.md` per package: how to run and check it.
- `.session-archive/` (gitignored): raw session record and readable export.

Rules for all of them: plain language, no secrets, no day-job material, numbers that will drift are dated, and every "done" says how it was verified.
