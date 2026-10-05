

## Triage (by the authoring agent, Claude Code, 5 Oct 2026)
Each finding was checked against the code before being accepted. The participant has not yet reviewed this triage.

Note on the reviewer: all six batches were answered by `gemini-flash-lite-latest`, the fallback. The first model did not answer (retired, over quota or overloaded; the script records the status only). A stronger model may find more; this run should not be read as "the code has only two faults".

| # | Verdict | What was done |
|---|---|---|
| chat-1 | **Real.** "how do I take ibuprofen", "what is the correct amount of paracetamol" and "when do I take paracetamol" were not treated as dosage questions. The story says dosage questions are refused | 14 failing unit tests added first, then five patterns added to `DOSAGE` in `chat.rules.ts`. Three control sentences ("what did I take for a sore throat" and similar) confirm recall questions are not caught. Checked live on the emulator |
| chat-2 | Not a fault. The reviewer talks itself out of it in its own text; a recall with no medicines is rejected by the guard, as intended | None |
| chat-3 | Not a fault. The reviewer first says `storage` is not cleaned, then notices it is. A null `storage` is handled: the app leaves out "How to keep it" (widget test exists) | None |
| records-1 | **Wrong.** The line it quotes does not exist: `mark()` already reads `where: { medicineId: dto.medicineId, userId }` | None. Recorded as a reviewer error |
| records-2 | Not exploitable. Ownership is checked by a `userId`-filtered read before the write by id; end-to-end tests prove another user gets 404. It is a fair point about a second line of defence | **For the participant to decide:** add `userId` to every write as well, or keep "check, then write by id" and state it in the coding standards |
| records-3 | Same as records-2, for notes | Same decision |
| records-4 | Low. The compare is done in memory because registration numbers are normalised before comparing; the database also has a unique index per user | None |
| app-1 | Low, real. A failed document download shows a fixed message, not the server's | Not changed: the fixed message is clear and the server's would add little. Listed for the participant |
| app-2 | **Real, low.** A reminder time the planner cannot read would throw and stop every reminder from being planned. The server only stores valid times, so it needs bad data to trigger | Failing test added first, then the planner skips a time it cannot read |

Count: 9 findings; 2 real and fixed, 1 real and left, 1 wrong, 2 not exploitable (decision needed), 3 not faults.

What the reviewer did not find, and a run on the emulator did the same night: a bare medicine name got the generic refusal when the lookup timed out (fixed, see `docs/06-qa/qa-strategy.md`).
