# Roadmap template

A reusable version of `docs/ROADMAP.md`. Days are counted from the start day (D1). The last column shows what this project actually took, for planning the next one.

## Phases
| Phase | Planned (28-day window) | Deliverables | This project |
|---|---|---|---|
| Explore and define | D1-D3 | Idea locked. PRD, journeys, stories with acceptance criteria and negative cases, "do / do not" page | D1 evening, about 1.5 hours |
| Design, context, skeleton | D4-D6 | Design file, data model, API description, ADRs, agent context file, skills, standards, CI, secret scan, health endpoint, first deploy | Skeleton D1; design D1, about 30 minutes; deploy not done |
| Build and test | D7-D20 | Vertical slices, each through spec, tests, code, review, CI | Built in one overnight session D1-D2, about 9 hours, outside the per-story loop |
| Hands-on round | (not in the original plan; add it) | Participant uses the app; one list of changes | D2, about 1.5 hours including changes |
| Hardening and review | D21-D22 | Edge cases, negative tests, security review, refactor, feature freeze | Not started |
| Polish and document | D23-D25 | UX polish, empty and error states, README, technical docs, QA write-up, limitations | Docs written D2; polish not started |
| Package | D26 | Demo video, secret scan of full history, ZIP from a clean clone, live link test | Not started |
| Submit | D27 | D28 is buffer | |

Lesson for planning: with an agent, the build is the short part. Budget the time for review, real-service checks, deployment and the submission package, which is where the score sits and which cannot be delegated.

## Per-story loop
1. Spec: story to acceptance criteria and API changes. Human reviews.
2. Tests first: failing tests.
3. Implement against spec and tests.
4. Review: a different model reviews the diff. Human reads every line.
5. CI green, then commit and merge.
6. Log any AI failure and the rule that changed.

## Rules to carry over
- No secrets in the repo; secret scan from day one.
- No day-job material.
- Fake data only.
- Vet new dependencies.
- Run analyze and tests before every commit; say what was tested.
- Do not report "% AI-generated code".

## Submission checklist
- [ ] Product description and problem statement
- [ ] Live demo link or build for judges (decide which, early)
- [ ] ZIP with the complete project and full Git history
- [ ] Technical doc: architecture, stack, decisions, limitations, dependencies
- [ ] AI development doc: workflow, context, skills, guardrails, failures log
- [ ] QA doc, including what was not tested
- [ ] Demo video
- [ ] Pre-existing work disclosed
- [ ] Secret scan on the final ZIP

## Scoring reminder (this hackathon)
AI development practice 35%, engineering and code quality 30%, product quality 25%, idea 10%. Bigger is not better; human ownership matters.
