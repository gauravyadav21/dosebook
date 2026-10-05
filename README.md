# DoseBook

Build With AI Hackathon project: **DoseBook**.

> A patient-side companion that makes you more aware of your own medicines: what you took, when, and what worked for you. We recall, we remind, we never prescribe.

Upload prescriptions, confirm what the AI read, get dose reminders, and ask "what worked for me" from your own history. See `docs/ROADMAP.md` and `AGENTS.md`.

- `backend/` NestJS + Prisma + PostgreSQL. Run and test: `backend/README.md`
- `mobile/` Flutter app, Android first. Run and test: `mobile/README.md`
- `samples/` fake prescriptions for the demo
- `docs/` requirements, architecture, standards, AI workflow, delivery, QA. Start at `docs/Home.md`; current status is at the top of `docs/ROADMAP.md`

Setup: `git config core.hooksPath .githooks` and `brew install gitleaks`. Backend needs Node 20.19+ and a local PostgreSQL 15+.

Limits to know: the app recalls and reminds and never prescribes; reading a prescription with a real model needs a Gemini key and has only been tested against a mocked response; chat is rule-based; nothing is deployed.
