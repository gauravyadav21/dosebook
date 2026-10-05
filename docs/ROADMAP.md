# Build With AI Hackathon 2026: Roadmap and Context Handoff

> For AI agents (Claude Code / OpenCode / Gemini CLI): read this file first. It holds the decisions, constraints and plan for this project. Follow the rules in section 8 at all times.

**Window:** 3 Oct to 30 Oct 2026 EOD. Judging 2-5 Nov, results 6 Nov. No changes after the deadline.
**Format:** individual, any tech, AI-agnostic, working MVP.
**Idea:** DoseBook (locked 4 Oct). A patient-side companion: upload prescriptions, confirm what was read, get dose reminders, recall what worked. We recall, we remind, we never prescribe. One user, one core journey, one polish feature (chat recall).

## 0. Status (updated 4 Oct 2026)
| Area | State |
|---|---|
| Idea, PRD, journeys, stories S1-S10 | Written. Open: participant's line-by-line review |
| Design | Figma file with 19 frames (`docs/02-architecture/design.md`). Four more screens exist only in the app |
| Architecture | Data model, OpenAPI export, ADRs 0001-0004 written |
| Backend | All stories implemented. 224 unit and 212 end-to-end tests pass locally |
| Mobile app (Android) | All screens implemented. 75 tests pass, debug build runs on the emulator |
| Web app | Not started. Deliberately left for later |
| Repo | **Nothing committed yet.** CI has not run. Nothing deployed |
| Owed before merge | Human review of every diff; cross-model review; check tests against stories (see `docs/04-ai/ai-workflow.md`) |

Changes to the plan below:
- Section 2: auth is local accounts with JWT (ADR 0002), not Firebase. The generated Dart client is not used; the app has a small hand-written client.
- Section 2: reading prescriptions uses Gemini Flash on the free tier when a key is set, a demo reader otherwise (ADR 0003). Chat uses fixed rules and no model.
- Section 5: the build phase planned for 9-22 Oct was done early in one session, outside the per-story loop. The time saved should go to review, hardening and the hosted demo.
- Section 11: items 1-3 are done except deployment.
- 4 Oct, after the first hands-on test: profile page (S10); notes became free text and own reminders moved to Today (S7); chat no longer asks for feedback, looks up medicines and declines anything else (S5); every screen refreshes itself (`add-screen` skill).
- Future scope added to the PRD: a measurements log (blood sugar, blood pressure and similar, with documents), and wider AI help in chat.

## 1. Scoring (optimise for this)
| Weight | Criterion | What wins it |
|---|---|---|
| 35% | AI Development Practice | AI across lifecycle, context engineering, AI-assisted QA, own agents/skills/instructions, human validation, learning from AI failures |
| 30% | Engineering / Code Quality | Architecture, tests, security, deployment, docs, documented trade-offs |
| 25% | Product Quality | Working core journey, UX, polish, completeness of scope (guide labels this row inconsistently) |
| 10% | Idea / Business | Low priority |

Principles from the guide: bigger is not better, complexity is not quality, more AI is not better AI, human ownership matters, and the amount of AI-generated code is not a success metric.

## 2. Stack decisions
- Mobile: Flutter (+ Flutter web hosted for judges)
- Backend: NestJS + Prisma + PostgreSQL, Swagger/OpenAPI generated, generated Dart client
- Auth: Firebase Auth (or JWT), input validation, authorization, rate limiting
- Skipped on purpose: Redis, queues, anything not serving the core journey
- Free hosting (verify current limits): Cloud Run / Render / Koyeb (backend), Neon / Supabase (Postgres), Firebase Hosting / Cloudflare Pages (Flutter web), GitHub Actions (CI). Warm the backend before judging (cold starts).

## 3. AI tool routing (zero cost, OpenCode as hub)
| Phase | Primary | Backup |
|---|---|---|
| Define and design | Gemini CLI | OpenCode + best Zen model |
| Build | OpenCode with Zen free models | Gemini CLI, then OpenRouter `:free` |
| Boilerplate, tests, docs | Groq or Cerebras via OpenCode | Zen |
| Inline completion | Copilot Free | none |
| Review | A different model from the author | swap roles |
| Final security review | Strongest available model | manual checklist + AI |

Status on 4 Oct 2026: this table is the plan, not what happened. The build so far was done with one paid tool. Trials of the free tools are tracked in `docs/04-ai/tool-trials.md`. The free Gemini CLI login is reported to have ended in June 2026; Google's replacement command (`agy`) has a small free quota.

Switch with `/models` in OpenCode. Commit after every working step so tools can be swapped mid-task. Free-tier limits change, so check live numbers. Keep this `AGENTS.md`-style context portable (copy to `GEMINI.md` / `CLAUDE.md` as needed).

## 4. Repo structure (context-engineering evidence)
```
AGENTS.md (+ GEMINI.md / CLAUDE.md copies)
.opencode/ or .claude/        skills + agents: spec-story, write-tests, review-diff, security-check
docs/
  01-requirements/   prd.md, user-journeys.md, stories/
  02-architecture/   architecture.md, openapi.yaml, data-model.md, adr/
  03-standards/      coding-standards.md
  04-ai/             ai-workflow.md, guardrails.md, ai-failures.md
  05-delivery/       deployment.md, env-vars.md (names only)
  06-qa/             qa-strategy.md
```

## 5. Timeline
| Dates | Phase | Deliverables |
|---|---|---|
| 3-5 Oct | Explore + Define | Idea locked. PRD, user journeys, stories with acceptance criteria |
| 6-8 Oct | Design + context + skeleton | OpenAPI, data model, ADRs, AGENTS.md, skills, standards. Repo with CI + gitleaks pre-commit, health endpoint. Backend and Flutter web deployed by 8 Oct |
| 9-22 Oct | Build + Test loop | 2-3 vertical slices per week, each through the loop in section 6 |
| 23-24 Oct | Test hardening + Review | Edge-case and negative-test passes, security review, refactor. Feature freeze 24 Oct |
| 25-27 Oct | Polish + Document | UX polish, empty/error states, README, technical docs, QA write-up, limitations |
| 28 Oct | Package | Record demo, scan full Git history for secrets, build ZIP from a clean clone, test live link |
| 29 Oct | Submit | 30 Oct is buffer only |

## 6. Per-story loop
1. Spec: AI turns the story into acceptance criteria and API changes; human reviews.
2. Tests first: AI drafts failing tests.
3. Implement: agent codes against spec and tests.
4. Review: a different model reviews the diff; human reads every line.
5. CI green, then merge.
6. Log any AI failure and the context/skill change made in response (`docs/04-ai/ai-failures.md`).

## 7. AI-assisted QA (document each in `docs/06-qa/qa-strategy.md`)
Test generation, unit tests/TDD, edge-case discovery, negative testing (bad input, expired token, accessing another user's data, network failure), AI-assisted debugging, cross-model code review. For each, record how the human validated the AI output. Full E2E automation is not required.

## 8. Rules and guardrails
- Never hardcode secrets. Full Git history is submitted, so run gitleaks from day 1. No keys in repo or ZIP.
- Do not reuse code, designs, data or requirements from day-job client projects, and never paste client code into AI tools. Disclose significant pre-existing work.
- Substantial implementation must be the participant's own; discussion, feedback and mentoring are fine.
- Do not use "% AI-generated code" as a metric.
- Free AI tiers may train on prompts: fake seed data only.
- Validate inputs, enforce authentication/authorization, protect data and APIs, vet new dependencies.
- Run analyze + tests before every commit. Human reviews every diff.
- Set spending caps on any funded API key.

## 9. Submission checklist
- [ ] Product description and problem statement, plus live demo link (access details shared separately, never in the repo)
- [ ] ZIP with the complete project and full Git history
- [ ] Technical doc: architecture, stack, decisions, limitations, dependencies
- [ ] AI development doc: workflow, context engineering, skills, agents, instructions, guardrails, failures log
- [ ] QA doc
- [ ] Demo video, max 5 minutes
- [ ] Pre-existing work disclosed
- [ ] Secret scan done on the final ZIP

## 10. Demo outline (5:00)
- 0:00-0:30 problem and user
- 0:30-2:00 live core journey
- 2:00-3:15 AI workflow: context files, a skill running, one real AI failure and the fix
- 3:15-4:15 architecture, two trade-offs, QA approach
- 4:15-5:00 limitations and next steps

## 11. Next actions
1. Review: read the diff, run `review-diff` with a different model, check tests against stories. Then commit in story-sized steps.
2. Push and get CI green (the workflow has a new Postgres service and has not run yet).
3. Get a Gemini API key, run the reader against the fake samples, measure accuracy, record it in `docs/06-qa/qa-strategy.md`.
4. Try the app on a real phone, including reminders arriving on time.
5. Decide on the web app and hosting; deploy backend and database by 8 Oct if the hosted demo stays in scope. Uploaded files need object storage on most free hosts (ADR 0004).
6. Fill the two trade-offs and the QA slide in `docs/07-slides/hackathon-deck.md`.
