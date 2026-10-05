---
theme: black
transition: slide
slideNumber: true
---

# DoseBook
Build With AI Hackathon 2026

A patient-side companion that makes you more aware of your own medicines.

We recall. We remind. We never prescribe.

---

## The problem

- Minor illnesses send people back to the doctor again and again
- Past prescriptions are scattered across paper and photos
- People forget what worked

---

## The user and the journey

One user: an adult managing their own minor illnesses.

1. Upload a prescription
2. AI extracts medicines, doses, dates
3. User reviews and confirms
4. Timeline of conditions and medicines
5. Dose reminders from the confirmed schedule
6. A contact card per doctor, built from the prescriptions: call, share, see all their prescriptions

---

## Polish: "What worked for me"

- Describe a minor symptom in chat
- Answer comes only from **your own** history, with dose, prescriber and your feedback
- Never invents a medicine and never prescribes: it recalls what a doctor already prescribed you

---

## Guardrails

- Recall-only, no new medicines or doses
- Allergies and "did not work" block suggestions
- Own notes and own reminders are labelled Self-added, never "prescribed"
- Nothing that needs a doctor's training: no diagnosis, no new medicines, no dose changes
- Doctor-vs-app reminder at first run, in chat, on every answer
- Red-flag symptoms redirect to a doctor
- AI output saved only after user confirms; reminders only from confirmed schedules
- Server-side check rejects any medicine not in history

---

## How AI was used

- Context files: AGENTS.md, skills (spec-story, write-tests, review-diff, security-check)
- Per-story loop: spec, tests first, implement, cross-model review, human reads every line
- Failures logged with the fix: see AI failures log
- The developer decides, the AI builds: scope line, safety limits and review come from the person; the AI's own defaults are listed and judged

---

## Architecture

- Flutter (mobile + web) to NestJS + Prisma + PostgreSQL
- OpenAPI generated, validated input, auth on every route, rate limiting
- Two trade-offs: TBD

---

## QA approach

- Tests first, negative tests (bad file, expired token, other user's data)
- Extraction accuracy measured on a fake prescription set
- How the human validated AI output: TBD

---

## Limitations and next steps

- A doctor report with charts
- Crowd insights: only with consented real data, aggregation, non-promotional framing and legal review
- Not a medical device; not a substitute for a doctor
- A proof of concept, not production-ready: still to come are a human security review, performance testing and validation with real users

---

## Demo timing (5:00)

| Time | Part |
|---|---|
| 0:00 | Problem and user |
| 0:30 | Live core journey |
| 2:00 | AI workflow, one real failure and the fix |
| 3:15 | Architecture, trade-offs, QA |
| 4:15 | Limitations and next steps |
