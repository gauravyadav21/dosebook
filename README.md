# DoseBook

Build With AI Hackathon project: **DoseBook**.

> A patient-side companion that makes you more aware of your own medicines: what you took, when, and what worked for you. We recall, we remind, we never prescribe.

Upload prescriptions, confirm what the AI read, get dose reminders, and ask "what worked for me" from your own history. See `docs/ROADMAP.md` and `AGENTS.md`.

- `backend/` NestJS + Prisma + PostgreSQL. Run and test: `backend/README.md`
- `mobile/` Flutter app, Android first. Run and test: `mobile/README.md`
- `samples/` fake prescriptions for the demo
- `docs/` requirements, architecture, standards, AI workflow, delivery, QA. Start at `docs/Home.md`; current status is at the top of `docs/ROADMAP.md`

Try it (judges): install the Android APK `dosebook-demo.apk` that comes with the submission. It talks to the demo server `https://dosebook.onrender.com`, which runs on a free plan and sleeps after 15 minutes without traffic, so the first request can take about a minute. Sign in with the demo login in `DEMO-ACCESS.md` at the top of the submission ZIP (kept out of the repository on purpose), or create your own account in the app. Upload only the fake prescriptions in `samples/`. Deployment details: `docs/05-delivery/deployment.md`.

CI: `.gitlab-ci.yml` runs a secret scan, the backend checks (lint, build, unit and end-to-end tests against PostgreSQL) and the app checks (analyze, tests, debug build) on every push. `.github/workflows/ci.yml` holds the same checks for a GitHub mirror.

Setup: `git config core.hooksPath .githooks` and `brew install gitleaks`. Backend needs Node 20.19+ and a local PostgreSQL 15+.

Limits to know: the app recalls and reminds and never prescribes; reading a prescription uses Gemini's free tier (tried live on the three samples on 30 and 31 Oct 2026), which can be slow or unavailable, and then the prescription is typed in by hand; chat is rule-based; the demo server and its database run on free plans.
