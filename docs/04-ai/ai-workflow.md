# AI workflow

How AI tools are used across the project, and where a person checks the result. Plan and tool routing: `docs/ROADMAP.md` sections 3 and 6.

## Context given to every tool
- `AGENTS.md` (copied to `CLAUDE.md` and `GEMINI.md`): the idea, stack, per-story loop and rules.
- `docs/01-requirements/`: PRD, journeys, one file per story with acceptance criteria, and `what-we-do-and-dont.md` as the single source for scope and wording.
- `docs/03-standards/coding-standards.md` and the ADRs in `docs/02-architecture/adr/`.
- Skills in `.claude/skills/`: `spec-story`, `write-tests`, `review-diff`, `security-check`.

## Where AI was used
| Phase | What AI did | What the person did |
|---|---|---|
| Define | Drafted PRD, journeys, stories S1-S9 and the scope document from the participant's idea | Chose the idea, set the limits ("recall, never prescribe"), added doctor contacts, answered scope questions |
| Design | Built the Figma file (tokens, components, 19 frames) from the stories | Chose style and scope; review of the frames is open |
| Architecture | Proposed the data model, API and ADRs 0002-0004 | Chose monolith, no AI in chat, free Gemini for reading, mobile only |
| Build | Wrote the backend and the mobile app | **Open: read every diff** |
| Test | Wrote unit, end-to-end and widget tests from the acceptance criteria; ran them; fixed what they caught | **Open: check the tests against the stories** |
| Review | Not done yet | Run `review-diff` with a different model, then read the result |

## Deviations from the per-story loop on 2026-10-04
The loop in `AGENTS.md` is: spec, human review, failing tests, implement, cross-model review, human reads every line, CI green, merge. On 2026-10-04 all nine stories were built in one unattended session at the participant's request. In that session:
- specs were not reviewed by a person story by story;
- tests were written with the code, not before it;
- no second model reviewed the diff;
- nothing was committed and CI has not run.

These steps are owed before the work is merged. `docs/06-qa/qa-strategy.md` lists what each check should cover.

## The developer's role
The AI builds a well-described thing well. It does not decide what is worth building, notice what is missing, or check against the real world unless told. In this project the scope line, the safety limits, the doctor-contact feature, the simpler notes, the narrower chat and the rule that every screen refreshes itself all came from the participant; the AI's own choices are marked "agent default" in `docs/08-build-log/decisions.md`. What the AI left out until told, and the checklists drawn from that, are in `docs/09-playbook/developer-judgement.md`.

## Tools tried
The roadmap planned a different tool per phase (section 3). So far one tool has done the work. Trials of the free tools, with the same four tasks for each and a record of pros, cons and failures, are in `tool-trials.md`. The roadmap's line naming Gemini CLI for define and design is out of date: its free login is reported to have ended in June 2026.

A review of each story commit by a different model (planned: Copilot's review on the pull request) is the cross-model review the per-story loop asks for.

## What is recorded
- Real failures and the rule each one changed: `ai-failures.md`.
- Tool trials and the pros and cons of each tool: `tool-trials.md`.
- Guardrails for the tools and for the product: `guardrails.md`.
