# Open items

Everything not done or not verified, in one list. Status on 4 Oct 2026. Update this file as items close.

## Must happen before the work counts
1. **Commit.** Done on 5 Oct 2026 as 12 story-sized commits (see `commit-plan.md`); pushed to GitLab the same night. Before that: nothing was committed. The roadmap submits the full Git history and scores the AI workflow from it. Commit story by story, following `commit-plan.md`.
2. **Human review of every diff.** Not done. Required by the roadmap and by `AGENTS.md`.
3. **Review by a second model** (`review-diff` skill). Not done.
4. **Check the tests against the stories.** The same agent wrote code and tests in one session, tests alongside rather than first.
5. **Get CI green.** Pushed on 5 Oct 2026. `.gitlab-ci.yml` (secret scan, backend with a Postgres service, mobile with an APK build) was added on branch `ci/gitlab`; it reaches `main` only after its first pipeline is green. The AI agent cannot read the pipeline result (private project, no API token), so the participant checks it under Build → Pipelines. `.github/workflows/ci.yml` is kept for a possible GitHub mirror and does not run on GitLab.

## To stand out (this project)
From `docs/09-playbook/standing-out.md`. None of these is done yet.
1. Measure reading accuracy: run Gemini on 15-20 fake prescriptions with known answers; record per-field accuracy and the misreads in `docs/06-qa/qa-strategy.md`. This also closes the PRD's open success criterion.
2. Write the demo script around the refusals: dosage, a red-flag symptom, an off-topic request, a non-medicine. Name the test behind each.
3. Produce the ownership evidence: review notes per story, a second model's findings and what was done about them, story-by-story commits.
4. Show one skill running in the video (`add-screen` or `review-diff`).
5. One slide: an AI failure before and after, with the rule that changed.
6. Add a risks column to the guardrails table (what could go wrong for a user).
7. Optional, only after review and commits: a one-page "show my doctor" summary of a prescription's history.
8. Try the free AI tools on the four standard tasks and record pros, cons and failures per tool: `docs/04-ai/tool-trials.md`. Only the tool used for the build has a sheet so far.

## Not verified
- Upload → review → schedule → confirm on a device. Covered by widget tests; the participant uploaded by hand once, the agent could not drive the file picker.
- The open Timeline updating right after Confirm on a device. Proven by a widget test; on the emulator only the resume refresh was seen.
- Reading a prescription photo with the live Gemini service. Mocked tests only.
- Medicine descriptions: one medicine looked up for real (ibuprofen). No text reviewed by anyone qualified. The dose filter is keyword-based.
- Notifications arriving at the right time. Only the planning logic is tested.
- On a device: password toggle, own-reminder add and edit, feedback chips on a prescription, Call, Share, doctor edit and delete.
- iOS, a real phone, the web build.
- Obsidian vault and slide deck were never opened in Obsidian by the agent.

## Not built
- Web app and a hosted link for judges; deployment of backend and database; object storage for uploads.
- Chat history is not saved between visits to the screen.
- Password reset, refresh tokens; token in secure storage.
- Email verification at sign-up (future scope by decision, 5 Oct 2026).
- Figma frames for the splash, visitor tab and Create account, and the logo sheet: script ready in `docs/02-architecture/assets/figma-s11-frames.js`, refused by the plan's call limit. iOS icon and launch screen not made.
- Custom reminder times for the named slots (fixed at 8:00, 13:00, 18:00, 21:00).
- PDF preview of the original document.
- Dark theme.
- Measurements log (future scope by decision).
- Wider AI help in chat (future scope by decision).

## Needs a decision or review from the participant
- "How to keep" was read as storage. Confirm.
- Whether judges get a web build or an APK plus video; the roadmap assumed a web link.
- Medical and legal review of: escalation wording, chat keyword lists, AI-written medicine descriptions.
- The free Gemini tier is acceptable only while all uploads are fake.

## After the rename to DoseBook
- Rename the Figma file title by hand.
- Rename the top folder and the notes folder (two `mv` commands in the build log entry for 5 Oct / given by the agent), then start a new session there and sign in to the Figma MCP again.
- iOS project identifiers were changed but not built.
- The old `medmem_app`, `medmem_dev` and `medmem_test` databases are still in the local cluster; delete them when no longer wanted.

## Docs still marked TBD
- Deck: "two trade-offs" and "how the human validated AI output" slides.
- Limitations write-up, pre-existing-work statement, demo video script.
- Figma frames for notes, chat, allergies and the profile are out of date or missing.

## Submission checklist (roadmap section 9)
| Item | State |
|---|---|
| Product description and problem statement | Written |
| Live demo link | Not started |
| ZIP with full Git history | Not possible until there are commits |
| Technical doc | Written |
| AI development doc | Written |
| QA doc | Written |
| Demo video | Not started |
| Pre-existing work disclosed | Not written |
| Secret scan on the final ZIP | Working tree scans clean; final scan pending |
