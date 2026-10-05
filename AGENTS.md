# AGENTS.md: project context for AI agents

Build With AI Hackathon 2026 (3 to 30 Oct). Read `docs/ROADMAP.md` first. Idea: DoseBook. A patient-side companion that makes you more aware of your own medicines: what you took, when, and what worked for you. We recall, we remind, we never prescribe. See `docs/01-requirements/prd.md` and `docs/01-requirements/what-we-do-and-dont.md`.

Before asking the participant anything, read `docs/08-build-log/` (build log, questions already answered, decisions, runbook, open items) and `docs/09-playbook/project-playbook.md` (standing answers and known pitfalls). Add to the build log, Q&A and decisions as work goes.

## Stack
- Mobile: Flutter (+ Flutter web for judges), in `mobile/`
- Backend: NestJS + Prisma + PostgreSQL, Swagger/OpenAPI, in `backend/`
- Auth: Firebase Auth or JWT; validate all input; enforce authorization; rate limit
- Skipped on purpose: Redis, queues, anything not serving the core journey

## Per-story loop
1. Spec: story to acceptance criteria and API changes; human reviews (skill: spec-story)
2. Tests first: failing tests (skill: write-tests)
3. Implement against spec and tests (skill: add-screen for any Flutter screen; every screen refreshes itself)
4. Review the diff with a different model than the author (skill: review-diff); human reads every line
5. CI green, then merge
6. Log any AI failure and the context/skill change made in `docs/04-ai/ai-failures.md`

## Rules
- Never hardcode secrets. Full git history is submitted. gitleaks runs on every commit.
- Do not reuse code, designs, data or requirements from day-job client projects. Never paste client code into AI tools.
- Fake seed data only (free AI tiers may train on prompts).
- Run analyze + tests before every commit. Human reviews every diff.
- Vet new dependencies. Set spending caps on any funded API key.
- Do not report "% AI-generated code" as a metric.
- Commit messages and docs carry no AI-tool attribution lines.
- Before committing, state what was tested and by whom. If it could not be tested, ask first.

## Standards
See `docs/03-standards/coding-standards.md`. Keep changes small; commit after every working step.
