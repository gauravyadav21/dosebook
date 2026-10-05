# The developer's thinking is the product

## The observation (participant, 5 Oct 2026)
A project built with AI shows the thought process of its developer: how they want the product built, what constraints they set, and the workflow they follow. "The AI did it, so anyone could have" is not true. Give the same tools to someone with a weaker thought process and things will still work, but not up to the mark, and the gap shows across the whole project. So the developer's job is to keep improving the knowledge that lets them guide the AI: to know what the AI does not do on its own, and make it do that.

This file turns that observation into something usable: what the developer decided here that the AI would not have, what the AI left out until told, and what to learn to guide it better.

## What the developer's thinking decided in this project
Source: the session record and `docs/08-build-log/decisions.md`. The middle column says where the idea started, because that is the honest evidence of ownership: some came from the participant outright, some were proposed by the AI and the participant judged and kept them. Judging a proposal is also the developer's thinking; it is just a different kind.

| Decision | Where it started | What it changed |
|---|---|---|
| The idea: a personal medicine memory built from prescriptions | Participant | The product |
| The chat recalls and never prescribes | AI proposed it; participant adopted it and asked for a page stating the difference | The whole safety design: fixed wording, escalation rules, a server-side guard |
| Keep one document of "what we do and do not do", usable for FAQ and privacy policy | Participant | The single source for scope and wording |
| "We are making people more aware of their own medicines" | Participant's framing; AI worded the line | The positioning line used everywhere |
| Cut to one core journey and one extra; park the doctor report and crowd features | AI advised; participant agreed after questioning the crowd feature | A scope that could be finished |
| Confirm step after reading a prescription | AI proposed; participant kept it | Nothing is saved without the user |
| Reminders from the confirmed prescription, with a follow-up | Participant | Stories S6 and the Today screen |
| A notes section and own reminders; remind the user of doctor versus app again and again; nothing needing a doctor's training | Participant | Stories S7 and S8; six fixed touchpoints |
| Show the doctor's details with every prescription; a card per doctor; share it; open all their prescriptions | Participant | Story S9, a feature the AI never proposed |
| Only the doctor's contact is shared; "not verified" line; never merge doctors by name alone | AI default, not yet reviewed | Limits on that feature |
| Monolith; no commits; mobile first; free model for reading photos; chat needs no AI | Participant | The shape of the build |
| Profile page and its fields | Participant | Story S10 |
| Notes should be plain text; reminders belong elsewhere | Participant, after using the app | A simpler product than the AI had built |
| Chat must not ask for feedback; anything else is declined | Participant, after using the app | A narrower, safer chat |
| Only say what a medicine is usually prescribed for and how to keep it; refuse dosage | Participant | The limit on what the model may say |
| The timeline did not update; every screen must refresh itself; make it a rule in a skill | Participant found the fault and set the rule; AI chose the mechanism | One shared mechanism and the `add-screen` skill |
| Save everything so the next project is faster | Participant | The build log, Q&A and playbook |
| Commit story by story | AI recommended; participant confirmed | The commit plan |
| Try several AI tools and record the faults of each | Participant | The tool-trials file |

## What the AI did not do until it was told, or at all
From this project's record. This is the list to check on any AI-built work.

- **It did not question the brief.** It built what was asked, including a notes screen the participant later simplified. Scope cuts came from being challenged.
- **It did not follow its own process when left alone.** Tests were written with the code, not first; no second model reviewed anything; nothing was committed in steps.
- **It did not call the real service.** Mocked tests passed while the real model name was retired.
- **It did not notice a stale screen.** Each screen passed its own test; the fault was between screens and was found by hand.
- **It wrote facts from memory**: a model name, a plugin's API, a weekday.
- **It chose defaults silently**: where the token is stored, fixed reminder times, files on local disk, how doctors are matched. All reasonable, none asked.
- **It did not check the surroundings**: it installed the app on whichever emulator was running.
- **It has not** deployed anything, run a security review, measured the model's accuracy, or had its medical wording reviewed. Nobody asked yet; it did not raise them as blockers either.

The pattern: the AI is strong at doing a well-described thing, and weak at deciding what is worth doing, noticing what is missing, and checking against the real world.

## What to know in order to guide it
The better the developer's own picture, the better the instructions. These are the areas that mattered here, with where to practise each in this repo (`docs/10-code-tour/`, `docs/09-playbook/learning-with-ai.md`).

| Know this | So you can tell the AI |
|---|---|
| The product's scope line | What it must never do, before it writes anything |
| Data modelling | What the tables are and who owns each row |
| Authentication and authorisation | "Every query filters by the user; another user's record is 404" |
| Validation | "Reject unknown fields; nested objects are required" |
| Where rules should live | "Rules are pure functions with tests, not inside screens" |
| Outside services | "Behind an interface; output is untrusted; timeout; fallback; save the result; run it once for real" |
| State on the client | "One place decides when screens reload" |
| Testing levels | Which test proves what, and what no test proves |
| Review | What to look for in a diff, and that someone other than the author looks |
| Delivery | Migrations, configuration, secrets, CI, deployment |
| The domain | Here: what counts as medical advice, and where the legal line is |

## Before handing a task to the AI: a checklist
1. Can I say in one sentence what this is for and what it must never do?
2. Have I written the acceptance criteria, including the cases that should be refused?
3. Have I named the constraints: free tier, no new dependency, platform, data rules?
4. Have I pointed to an existing pattern to copy?
5. Have I said how it will be checked, and which checks must be real (not mocked)?
6. Have I asked for a plan first, and read it?

## A line worth reusing (added 5 Oct 2026)
From a blog post the participant read, put in our own words: what an AI builds quickly is a proof of concept, not production-ready code. It still needs validation, a security review, performance testing, and the checks only the user can make. "It runs" is where that work starts. Use this line whenever the project is described; for this project the list of what is still unvalidated is `docs/08-build-log/open-items.md`.

## After the AI hands work back
1. What did it decide without asking? List it and judge each.
2. What did it not verify? It should say; if it does not, ask.
3. Does it work between parts, not only within each part? Try it by hand.
4. Could I explain each file? If not, ask for a tour before accepting.
5. What rule would have prevented each fault found? Write the rule down where the AI reads it.

## Why this matters for a hackathon
The judges cannot see effort; they can see judgement. The scope page, the decisions table that separates the developer's choices from the AI's defaults, the failures log with the rule each failure produced, and a history of small reviewed commits are that judgement made visible. See `standing-out.md`.
