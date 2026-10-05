# Standing out when every team uses AI

Everyone at an AI hackathon ships a working app. What differs is proof: of quality, of judgement, and that the work is yours. Do not add features to stand out. Check the scoring first; here it was AI practice 35%, engineering 30%, product 25%, idea 10%, with "bigger is not better" and "human ownership matters" stated as principles.

The reason this works: an AI-built project shows its developer's thinking, and that thinking is what differs between teams (`developer-judgement.md`).

Each point below is an action and the evidence it leaves. Advice given 4 Oct 2026; none of it had been carried out at the time of writing unless marked done.

## Proof of quality
| Do | Evidence it leaves | Where |
|---|---|---|
| Measure the AI. Run the model on 15-20 fake inputs with known answers; report accuracy per field and list the failures | A table of numbers and a list of misreads | `docs/06-qa/qa-strategy.md` |
| Replace adjectives with numbers: tests per story, negative tests, lookups served from the database versus the model, response time first call versus repeat | Figures that can be checked | QA doc, deck |
| State the limits up front: what is not tested, not built, not reviewed | A "not verified" list | `docs/08-build-log/open-items.md` (done) |
| Write one threat-model page: what could go wrong for a user (wrong number, wrong dose text, another user's data, model invents something) and what stops each | A table of risk, control, test | `docs/04-ai/guardrails.md` (controls and tests done; risks column to add) |

## Proof of judgement
| Do | Evidence it leaves | Where |
|---|---|---|
| Make safety the headline. Demo the refusals on purpose: dosage, red-flag symptom, off-topic request, a non-medicine | A demo section "watch it say no", each backed by a named test | Demo script, deck |
| Keep a real failures log: what went wrong, why, which rule changed | Dated rows | `docs/04-ai/ai-failures.md` (done, 11 rows) |
| Show one failure before and after: the bug, the test that now catches it, the rule added to the agent's instructions | One slide | Deck |
| Keep a short list of what you rejected from the AI and why (a suggestion declined, a default overruled) | 5-10 lines | `docs/08-build-log/decisions.md` marks agent defaults; add a "rejected" section as it happens |
| Record trade-offs as decisions with reasons, not as outcomes | ADRs | `docs/02-architecture/adr/` (done) |

## Proof the work is yours
| Do | Evidence it leaves | Where |
|---|---|---|
| Commit story by story, each with what was tested | A readable history | `docs/08-build-log/commit-plan.md` |
| Review every diff and leave notes; have a second model review and keep its findings and what you did about them | Review notes per story | `docs/06-qa/`, PR or commit notes |
| Write the specs and the scope line yourself; let the AI fill in, not decide | Stories and the "do / do not" page in your words | `docs/01-requirements/` |
| Build and show one skill or instruction of your own, running | A clip in the video | `.claude/skills/` (`add-screen`, `review-diff`) |
| Be able to explain any file when asked | You, in the Q&A | See `learning-with-ai.md` |

## If you add anything to the product
- At most one addition, and only one that deepens the theme instead of opening a new area. For this project: a one-page "show my doctor" summary of a prescription's history.
- Do it after review and commits, never before.
- Put everything else under future scope with the reason it is out.

## The demo
- Open with the problem in one sentence and the scope line ("we recall, we remind, we never prescribe").
- Show the core journey once, at normal speed.
- Then show three refusals and one AI failure with its fix.
- End with the numbers and the limits. Saying what is not done reads as control, not weakness.

## What not to do
- Do not report how much code the AI wrote.
- Do not claim something works that was only tested against a mock; say so.
- Do not add a feature the night before to look bigger.
