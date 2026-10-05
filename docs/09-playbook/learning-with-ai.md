# Learning with AI, not only delegating to it

The participant's aim (4 Oct 2026): build applications with AI, but also understand what was built, know which code does what, and learn to guide the AI so it codes well. This file is the method. An agent reading it should explain as it builds and offer to teach, not only deliver.

Why this matters, and what the AI does not do unless told: `developer-judgement.md`.

## Understanding code the AI wrote
1. **Guided tour of one flow.** For this project the tours are written: `docs/10-code-tour/` (seven flows, each with things to try and questions). For a new project, ask: "Walk me through what happens from tapping Confirm to the row in the database, file by file, and why each step exists." One flow at a time. Flows in this project worth touring: sign-in and the token; upload to confirm; a dose from schedule to notification; a chat message through the rules; how a screen refreshes itself.
2. **Read the tests first.** Each test name is one sentence about what the code does. `backend/test/*.e2e-spec.ts` reads like the acceptance criteria.
3. **Make one small change yourself.** A label, a validation limit, a new allergy rule. Run the tests and see what breaks. Do this before asking the AI to do it.
4. **Question every diff.** Before accepting: "Why this way? What was the alternative? What breaks if I remove this line?"
5. **Explain it back.** Pick a file, explain it in your own words, and ask the AI to correct you. This finds the gaps faster than reading.
6. **Break it on purpose.** Remove a check (for example the user filter on a query) and watch which test fails. That shows what each guard is for.
7. **Trace one request by hand.** Open Swagger at `/docs`, call an endpoint, then find its controller, its validation class, its database call and its test.

## Prompts worth reusing
- "Explain this file to someone who knows programming but not this framework. Then list the three things most likely to go wrong in it."
- "Before writing code, give me the plan and the two alternatives you rejected."
- "Do not write the code. Tell me what to type and why, one step at a time, and wait for me."
- "Review this diff as a strict reviewer. List bugs, missing tests and missing validation, most serious first."
- "What would a senior engineer ask about this design?"
- "Write the failing test first and show me it failing."

## Guiding the AI to code well
The AI follows what is written down. Put the design on paper before the code.
- **A one-page spec per feature**: what it does, what it must never do, acceptance criteria, negative cases (bad input, no token, another user's data).
- **An ADR for each real choice**: context, decision, trade-offs. Auth, storage, where AI is called, data shape.
- **Standing rules** in the agent context file and the coding standards: "every query filters by the user", "every screen loads through Loader", "a nested object needs IsDefined". Add a rule each time a mistake happens; that is what stops it recurring.
- **Plan first.** Ask for a plan with checkpoints and correct the plan. Correcting a plan costs a paragraph; correcting code costs a rebuild.
- **Name the constraints**: free tier only, no new dependency without saying so, no commit, phone width, fake data.
- **Give examples from your own code**: "follow the pattern in `doctors.controller.ts`" beats a description.
- **Ask for the test with the code**, and for what was not tested.
- **Small steps.** One story at a time; review; commit; next.

## System design topics to learn, mapped to this project
One topic a week is enough. For each: read the file, ask for a tour, change something small.

| Topic | Why it matters | Where to see it here |
|---|---|---|
| Data modelling | Everything else follows from the tables | `backend/prisma/schema.prisma`, `docs/02-architecture/data-model.md` |
| API design and validation | Bad input is the most common bug | `backend/src/prescriptions/prescriptions.dto.ts`, Swagger at `/docs` |
| Authentication and authorisation | Who you are versus what you may see | `backend/src/auth/`, the user filter in every controller |
| Business rules as pure functions | Testable without a server | `backend/src/chat/chat.rules.ts`, `backend/src/doses/doses.logic.ts` |
| Calling outside services safely | Timeouts, fallbacks, untrusted output, caching | `backend/src/common/gemini.ts`, `backend/src/medicine-info/` |
| State and refresh on the client | Stale screens are the most visible bug | `mobile/lib/widgets/common.dart` (`Loader`), `mobile/lib/app/app_scope.dart` |
| Testing levels | Unit, end-to-end, widget: what each proves | `*.spec.ts`, `backend/test/`, `mobile/test/` |
| Migrations | Changing a database without losing data | `backend/prisma/migrations/` |
| Secrets and configuration | What goes in `.env` and why | `backend/src/common/config.ts`, `docs/05-delivery/env-vars.md` |
| Deployment and CI | Not done yet in this project; learn it by doing it | `.github/workflows/ci.yml` |

## Reviewing AI-written code: a checklist
- Does it do what the story says, including the negative cases?
- Is every input validated, and every query limited to the signed-in user?
- Is there a test for each acceptance criterion? Did I see it fail first?
- Any new dependency? Any secret, URL or key in the code?
- Is anything claimed as working that was only tested against a mock?
- Can I explain each file in two sentences?
- What did the AI decide without asking? (Mark it as an agent default in the decisions table.)

## When to write the code yourself
- The scope line and the fixed wording: the words are the product.
- The first example of a new pattern, so the AI copies yours.
- Anything you could not explain if asked.
- Small fixes during review: faster than a prompt, and it keeps your hands in.
