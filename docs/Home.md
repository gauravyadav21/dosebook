# Hackathon vault: DoseBook

> A patient-side companion that makes you more aware of your own medicines: what you took, when, and what worked for you. We recall, we remind, we never prescribe.

This `docs/` folder is the Obsidian vault. Open it via Obsidian: Open folder as vault, choose `docs/`. Notes ship with the repo and git history.

- [[ROADMAP]] plan, scoring, timeline, rules
- [[01-requirements/what-we-do-and-dont|What we do and don't (FAQ, privacy wording)]]
- [[01-requirements/prd|PRD]], [[01-requirements/user-journeys|User journeys]]
- [[02-architecture/data-model|Data model]], [[02-architecture/design|UI design (Figma)]], API: `02-architecture/openapi.json`
- ADRs: [[02-architecture/adr/0001-stack|0001 stack]], [[02-architecture/adr/0002-auth|0002 auth]], [[02-architecture/adr/0003-extraction-and-chat|0003 where AI is used]], [[02-architecture/adr/0004-files-and-reminders|0004 files and reminders]]
- [[03-standards/coding-standards|Coding standards]]
- [[04-ai/ai-workflow|AI workflow]], [[04-ai/guardrails|Guardrails]], [[04-ai/ai-failures|AI failures log]], [[04-ai/tool-trials|AI tool trials]]
- [[05-delivery/env-vars|Env vars]]
- [[06-qa/qa-strategy|QA strategy]]
- [[07-slides/hackathon-deck|Pitch deck]] (Advanced Slides)
- Build record: [[08-build-log/build-log|Build log]], [[08-build-log/questions-and-answers|Questions and answers]], [[08-build-log/decisions|Decisions]], [[08-build-log/runbook|Runbook]], [[08-build-log/open-items|Open items]], [[08-build-log/commit-plan|Commit plan]]
- Code tour (which file does what, and why): [[10-code-tour/README|start here]]
- For the next project: [[09-playbook/project-playbook|Project playbook]], [[09-playbook/developer-judgement|Developer judgement]], [[09-playbook/standing-out|Standing out]], [[09-playbook/learning-with-ai|Learning with AI]], [[09-playbook/cost-and-tools|Cost and tools]], [[09-playbook/roadmap-template|Roadmap template]], [[09-playbook/docs-template|Document set]]

## Conventions
- Daily notes in `daily/` from the daily template: log AI use, failures and human validation as you go. This is the raw evidence for the AI development doc.
- Templates in `templates/` (story, ADR, AI failure row).
- Fake data only. No secrets, no day-job content in this vault.

## Plugin setup (one-time, per machine)
Settings, Community plugins, turn off Restricted mode, Browse, install and enable "Advanced Slides". Open the deck note and run "Show slide preview".
