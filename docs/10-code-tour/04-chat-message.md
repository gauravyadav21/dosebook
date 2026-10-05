# Tour 4: a chat message

Follows: you type a message in chat and get an answer. Then the branch where a medicine is looked up and, the first time, fetched from Gemini.

The chat does two things: recall what you took before for a symptom, and look up a medicine. Everything else is refused or sent to a doctor. Almost all of that is decided in one file of plain rules, with no AI in it.

## The path
1. **`mobile/lib/features/chat/chat_screen.dart`, `_send`.** Adds your message to the list on screen and calls `api.chat`. The conversation lives only in this screen's memory; it is gone when you leave the screen.
2. **`mobile/lib/api/api.dart`, `chat`.** `POST /chat` with `changes: false`, so asking a question does not make every screen reload.
3. **`backend/src/chat/chat.controller.ts`, `chat`.**
   - Loads your prescription medicines (with condition, doctor and date) and your allergies. Own reminders and notes are not loaded: chat never uses them.
   - Turns them into a flat list of `HistoryItem`.
   - Calls `decide`.
   - Whatever comes back goes through `guard` before it is returned.
   - The route has its own, lower rate limit because a lookup can cost a model call.

## The rules: `backend/src/chat/chat.rules.ts`, `decide`
Read this function with the file open. The order is the safety design: anything that needs a doctor is caught before anything is recalled.

| Step | Function | What it checks | Answer |
|---|---|---|---|
| 1 | `classify` → `RED_FLAGS` | chest pain, trouble breathing, fainting, heavy bleeding and similar | `ESCALATION`: the fixed "This needs a doctor's attention" text, no medicines |
| 2 | `asksDosage` → `DOSAGE` | dose, dosage, how much, how many, how often, "500 mg", "more tablets" | `DECLINED` with `DOSAGE_TEXT`: not recommended, visit your doctor |
| 3 | `classify` → `OUT_OF_SCOPE`, `PERSISTENT` | new medicine, stopping a course, pregnancy, a child, interactions, diagnosis; weeks, getting worse, keeps coming back | `ESCALATION` |
| 4 | `matchesMessage` | does the message match the condition a past medicine was prescribed for? | go to step 5 |
| 5 | `isBlocked` | drop medicines marked "did not work" or "side effect", or matching an allergy | `RECALL` with what is left; `ESCALATION` if nothing is left |
| 6 | `findMedicine` | a medicine from your records named in the message; or "what is X"; or a bare one- or two-word message | a `LookupRequest` (see below) |
| 7 | `SYMPTOM_CUES` | does it read like a symptom? | `NO_HISTORY`: nothing in your records, see a doctor |
| 8 | otherwise | | `DECLINED`: "I can do two things…" |

How matching works (`matchesMessage`, `tokens`, `singular`): the message and the condition are lower-cased and split into words, common words are removed, plurals are reduced ("allergies" to "allergy"), and a match needs a specific word in common, or the condition written with or without a space ("head ache" matches "Headache"). It is literal on purpose: a miss gives "see a doctor", which is the safe side.

## The last check: `guard`
Every answer passes through `guard` before leaving the server, whatever produced it. It turns the answer into an escalation if:
- a medicine is not in your history, or its name or dose differs from what is stored;
- a blocked medicine appears in a recall;
- an escalation or a decline carries a medicine list;
- the doctor-vs-app line is missing;
- general information is present without its "not advice" line.

With rules alone this can hardly fail. It exists so that if a model is ever put in front of the rules, it cannot slip something through.

## The lookup branch
When `decide` returns a `LookupRequest`, the controller continues:

1. **`chat.controller.ts`** calls `medicineInfo.find(name)`. Only the medicine name is passed, never your message or your data.
2. **`backend/src/medicine-info/medicine-info.service.ts`, `find`.**
   - Looks in the `MedicineInfo` table first (`medicineKey` makes "Ibuprofen", "IBUPROFEN" and " ibuprofen " the same key). If found, return it. No model call.
   - No row and no Gemini key: "unknown".
   - Otherwise call the provider. If it says "not a medicine", nothing is saved. If it returns a description, save it with `upsert` and return it. Any error is logged and treated as "unknown".
3. **`backend/src/medicine-info/gemini-medicine-info.ts`, `lookup`.** The prompt asks for exactly two facts: what the medicine is usually prescribed for, and how to keep it. The name is put in with `JSON.stringify`, so a name containing quotes or new lines cannot rewrite the instructions. Only the `usedFor` and `storage` fields are read from the reply; anything else the model adds is ignored.
4. **`backend/src/common/gemini.ts`, `geminiJson`.** Tries the first model; on 404, 429, 500 or 503 tries the second. The key goes in a header, never in the URL. An error carries only the HTTP status.
5. **`backend/src/medicine-info/medicine-info.ts`, `cleanSummary`.** Splits the text into sentences and removes any that read like a dose or an instruction ("500 mg", "take", "every 6 hours", "recommended"), then caps the length. If nothing safe is left for `usedFor`, the result is discarded.
6. **Back in the controller.** If it is not a medicine, or it was only a bare word with no record and no description: `declined()`. Otherwise `medicineInfoAnswer` builds the reply: your own records of it (even if you marked it, because this is your record, not a suggestion), the two general facts, and `allergyMatch` if it matches an allergy.

## What the app shows
**`chat_screen.dart`, `answerWidgets`:** an escalation shows only the fixed `EscalationCard`. Anything else shows the text bubble with the footer line, then an allergy banner if flagged, the "About" card if there is general information, and one card per medicine with "No feedback recorded" or your feedback. There are no feedback buttons here.

## Tests that prove it
- `backend/src/chat/chat.rules.spec.ts`: each rule, each dosage phrasing, and the `guard` with deliberately broken answers.
- `backend/test/chat.e2e-spec.ts`: "fetches general information once, saves it, and answers later lookups from the saved copy", "sends only the medicine name to the lookup, never the message or user data", "declines and saves nothing when the name is not a medicine", "does not call the lookup for symptoms, red flags, dosage questions or long off-topic messages".
- `backend/src/medicine-info/medicine-info.spec.ts`: `cleanSummary`, the fallback model, the quoted name.

## Agent defaults to question
- The keyword lists (`RED_FLAGS`, `DOSAGE`, `OUT_OF_SCOPE`, `SYMPTOM_CUES`) were written without medical review and are English only.
- The dose filter is keyword-based; a model can phrase things it will not catch.
- A bare one- or two-word message is treated as a possible medicine name, which costs a model call.
- AI-written descriptions are shared by all users and have never been reviewed by anyone qualified.

## Things to try
1. Add "numbness" to `RED_FLAGS`. Write the test first in `chat.rules.spec.ts` (copy a row in the red-flag list), see it fail, then add the word.
2. In `decide`, move the `asksDosage` line below the recall block. Run `npm test`. Read which tests fail and what would have reached the user.
3. In Prisma Studio, edit the `summary` of the ibuprofen row, then ask the app "what is ibuprofen". What do you see, and what does that tell you about where the text comes from?
4. Ask "what is ibuprofen" for a medicine that is not saved and watch `/tmp/claude-meta/backend.log` (or the terminal running the backend).

## Check your understanding
1. Why are red flags checked before anything else?
2. What exactly is sent to Gemini for a lookup?
3. A model reply contains `"sideEffects": "..."`. What happens to it?
4. Why does `guard` exist if the rules are already correct?
5. Why does a lookup show a medicine you marked "side effect", when a recall would not?

Answers: (1) So a message like "paracetamol for chest pain" never gets a medicine list. (2) The fixed prompt and the medicine name, nothing else. (3) It is ignored; only `usedFor` and `storage` are read. (4) It is the last line of defence for any future producer of answers, such as a model. (5) A lookup shows your own record of something you asked about; a recall is the app offering it for a symptom.
