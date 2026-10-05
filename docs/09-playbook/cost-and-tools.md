# Cost and tools

How to keep AI cost down and how to choose tools. Written 4 Oct 2026 from this project's session record.

## Where the cost went
In the main build session, about 0.5 million tokens were written as output and about 97 million were re-read from cache. Long sessions are expensive mostly because every new step re-reads everything before it. So the savings are in session shape, not in shorter answers.

## Habits that cut cost
- **One session per phase.** Start a new session for design, build, hands-on changes, review. Give it `docs/08-build-log/build-log.md`, `open-items.md` and `docs/09-playbook/project-playbook.md` as context instead of the old conversation.
- **Decide before building.** Answer all open questions in one round. A change of direction mid-build re-reads the whole session.
- **Batch changes.** One message listing all changes after trying the app is cheaper than one change per message.
- **Plan, approve, let it run.** Interruptions cost more than a wrong default fixed afterwards.
- **Strong model for planning and review; cheaper model for routine code, tests and docs.**
- **Let tests verify.** Screenshots and emulator walks are slow and costly; use them only for what tests cannot show.
- **Point to files, do not paste them.** "Follow the pattern in X" instead of pasting X.
- **Keep answers in files.** Recurring questions go to `questions-and-answers.md` and `runbook.md`, so the next session reads a page instead of asking.
- **Stop a session** when the phase is done, when it starts repeating itself, or when the topic changes.

## First message of a new session
1. What this session is for, in one line.
2. "Read `AGENTS.md`, `docs/08-build-log/open-items.md` and `docs/09-playbook/project-playbook.md` first."
3. The constraints that matter today (no commits, mobile only, free tier).
4. What "done" looks like and how it will be checked.

## Choosing a tool
Free tools vary and change. Do not trust a list, including this one; run a trial.

**Trial method (about an hour):** pick one small story with tests already written. Give the tool the story, the context file and the standards. Judge by: do the tests pass, how many corrections did it need, did it follow the standing rules, did it invent anything. Record the result here.

| Tool (named in the roadmap) | Planned use | Tried on this project? | Result |
|---|---|---|---|
| Claude Code | Used for everything so far | Yes | Built the project; paid; cost figures in `build-log.md` |
| Gemini CLI / `agy` | Define and design | No | Not tried. Reported 4 Oct 2026: the free Gemini CLI login ended in June 2026; the replacement has a small daily quota |
| OpenCode with free models | Build | No | Not tried. Installed on the Mac |
| Groq or Cerebras via OpenCode | Boilerplate, tests, docs | No | Not tried. Reported free limit: about 30 requests a minute, 1,000 a day |
| Copilot Free | Inline completion; review of each commit | No | Not tried. Reported free limit: 2,000 completions and 50 chat, agent or review requests a month |
| A different model for review | Cross-model review | No | Not done; required by the roadmap |
| Gemini API free tier (inside the product) | Reading prescriptions, medicine descriptions | Yes | Works; the newest model was often overloaded, the lighter one answered |
| Figma MCP (Starter plan) | Design | Yes | Works; 3 pages per file and a low daily call limit |

Trials are recorded in `docs/04-ai/tool-trials.md`, which has the four standard tasks, the prompts and a record sheet. Copy that file into a new project and reuse the tasks.

## What must never go to a free tier
Free tiers may use what you send to improve their products.
- Real personal or health data. Fake data only.
- Day-job code, designs, data or screenshots.
- Secrets and keys.

## Free-tier limits met so far
- Gemini: a retired model name returns 404 for new keys; the newest model returned 503 and 429 under load. Use the `-latest` alias and a fallback.
- Figma Starter: 3 pages per file; the tool-call limit was reached after about 25 calls in a day.
- AI Studio key creation asked for a card when reached through the Cloud Console; the free key comes from AI Studio itself.

## Design work with AI
- Decide tokens (colours, spacing, type) to match the app's theme first, then components, then screens.
- Batch design calls: tokens and components in one or two large calls, screens in a few. Many small read and screenshot calls spend the daily limit.
- Keep a frame-to-story table so design and requirements stay in step, and note which frames are out of date after product changes.
