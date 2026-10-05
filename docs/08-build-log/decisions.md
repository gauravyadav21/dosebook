# Decisions

Every decision taken, who took it, and why. "Participant" means the decision was made or approved by the participant; "agent default" means the AI agent chose it without being asked and it has not been reviewed. Written 4 Oct 2026.

## Product

| Decision | By | Why | Recorded in |
|---|---|---|---|
| Idea: personal medicine memory for one adult managing minor illnesses | Participant | Own idea | PRD |
| One core journey (upload, read, confirm, timeline, reminders) and one polish feature | Participant, on agent advice | Roadmap scoring: bigger is not better | PRD |
| Polish feature is the "what worked for me" chat | Participant | Chosen over the doctor report | PRD |
| Chat recalls and never prescribes | Participant, on agent advice | Prescribing is a doctor's job and a regulated activity | `what-we-do-and-dont.md` |
| Crowd/area medicine insights and doctor report are future work | Participant, on agent advice | Legal and data risk; scope | PRD |
| Reminders are part of the core journey | Participant | Fits the confirm step | S6 |
| Notes section and own reminders | Participant | Own request | S7 |
| Doctor-vs-app wording repeated at fixed points | Participant | Own request | S8 |
| Doctor contact cards; share a card; Doctor tab on a prescription; all prescriptions from a card | Participant | Own request | S9 |
| Only a doctor's contact is shared, never medicines; "not verified" line; never merge doctors by name alone | Agent default | A wrong number or a silent merge is a real risk | S9 |
| Profile page with name, date of birth, sex, height, weight, blood group, emergency contact, long-term conditions, allergies | Participant | Own request and chosen fields | S10 |
| The app does not advise from profile data | Agent default | Scope line | S10 |
| Notes are plain text only; own reminders move to Today | Participant | Own request | S7 |
| Chat does not ask for feedback; feedback is given on the prescription at any time | Participant | Own request | S4, S5 |
| Chat does only symptom recall and medicine lookup; declines the rest; red flags still escalate | Participant (red flags: agent default) | Own request; safety | S5 |
| Medicine lookup shows only "usually prescribed for" and "how to keep it"; dosage is refused | Participant | Own request | S5 |
| "How to keep" means storage | Agent's reading, not confirmed | Ambiguous wording | S5 |
| Measurements log (sugar, blood pressure, documents) is future scope | Participant | Own request | PRD |
| Product name is DoseBook; application id `com.dosebook.app` | Participant, from names the agent suggested | Short, says what it is. The agent noted that "Dose" may suggest dosage advice, so the tagline "we never prescribe" stays beside the name | README, PRD |

## Technical

| Decision | By | Why | Recorded in |
|---|---|---|---|
| Flutter, NestJS, Prisma, PostgreSQL | Participant (roadmap) | Roadmap section 2 | ADR 0001 |
| One NestJS application with feature modules | Participant | "Monolith" | Coding standards |
| Mobile (Android) first; web left for later | Participant | Own instruction | ROADMAP status |
| No commits until the participant reviews | Participant | Standing rule | `AGENTS.md` |
| Commit story by story, from a written plan | Participant | The history is submitted and scored | `commit-plan.md` |
| Local accounts, scrypt, JWT; not Firebase Auth | Participant asked for local auth; details agent default | No second service | ADR 0002 |
| Token kept in app preferences, not the keystore | Agent default | Fewer native dependencies; noted as a follow-up | ADR 0002 |
| Reading a photo: Gemini Flash free tier, called from the backend, behind an interface, demo reader without a key | Participant chose a free model; placement agent default | Key stays on the server | ADR 0003 |
| Chat is rule-based, no model | Participant | "We don't need any API" | ADR 0003 |
| One-time AI fetch of a medicine description, saved and reused | Participant | Own request | ADR 0003 |
| Model alias `gemini-flash-latest` with a fallback model | Agent default | The first choice was retired; the newest was overloaded | ADR 0003 |
| Calendar dates stored as text | Agent default | No time-zone shifts | data-model |
| Another user's record returns 404 | Agent default | Does not reveal that it exists | Coding standards |
| Files on local disk under random names; type checked from content | Agent default | No object storage in scope | ADR 0004 |
| Reminders are local notifications planned on the phone; server sends no push | Agent default | No push service in scope | ADR 0004 |
| Local PostgreSQL by script, no Docker | Agent default | Docker not installed; PostgreSQL 15 was | backend README |
| Every screen loads through one `Loader` that refreshes itself | Participant asked for auto refresh everywhere; mechanism agent default | A stale Timeline was found by hand | `add-screen` skill |
| Material 3, indigo seed, Roboto, 412 px frames | Participant | Matches the Flutter skeleton | design.md |

## Record and reuse

| Decision | By | Why |
|---|---|---|
| Raw session record copied into the project but kept out of git | Participant | It contains off-topic and day-job screen text |
| Reusable playbook as a document in the repo only | Participant | No change to global settings |
| Docs live in an Obsidian vault inside the repo | Participant | Notes ship with the history |
| The app opens without sign-in; sign-in is asked for only when an action needs to know the user, including medicine lookup (5 Oct 2026) | Participant | Let a visitor see what the app is first |
| Visitor tabs explain the feature; no sample data | Participant (chose from two options) | Examples must never be mistaken for the user's own medicines |
| Sign-up is its own screen; email verification is future scope | Participant | Keep the first version simple |
| After sign-in the action the visitor asked for continues, except for a new account, which sees the acknowledgement first | AI default, not yet reviewed | The acknowledgement must come before any use (S8) |
| An expired session returns to the visitor tabs with a message, not to a sign-in screen | AI default, not yet reviewed | Follows from sign-in no longer being a root screen |
| Logo: open book with a capsule, drawn in code, no image package | AI proposed; participant has not yet seen it | No new dependency; one drawing reused for icon, launch screen and app |
| Commit author is the participant's official ID and email, set for this repository only; no personal address | Participant | Own instruction, 5 Oct 2026 |
| Commits 1 to 5 verified one at a time; from commit 6 go on without stopping, push at the end | Participant | Own instruction |
| "Proof of concept, not production-ready" kept as a reusable line, not a separate document | Participant | It is a point to use when describing the work |
