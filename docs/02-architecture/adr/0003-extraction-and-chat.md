# ADR 0003: Where AI is used in the product, and where it is not

Status: accepted. Date: 2026-10-04.

## Context
Two features could use a model: reading a prescription photo, and the "what worked for me" chat. The budget is zero and the product must never prescribe.

## Decision

### Reading a prescription: Gemini Flash on the free tier, called from the backend
- `Extractor` interface in `backend/src/extraction/`. With `GEMINI_API_KEY` set, `GeminiExtractor` sends the file and asks for strict JSON. Without a key, `DemoExtractor` returns fixed fake data for the bundled samples in `samples/` and nothing for any other file.
- The model's answer is untrusted. `normalizeExtraction` keeps only known fields, trims and caps text, and rejects a result with no medicine. The result is shown to the user for review and saved only on Confirm.
- Any failure or timeout falls back to manual entry.
- Called from the backend, not from the app, so the key never ships inside an installable app and the server's auth and rate limit apply. Firebase AI Logic would call the same model from the phone and needs a Firebase project and App Check.

### Chat: fixed rules; a model only for a one-time medicine description
- Chat does two things: symptom recall and medicine lookup. Anything else is declined with a fixed message.
- `backend/src/chat/chat.rules.ts` decides every answer from the user's own confirmed prescriptions, feedback and allergies. Own reminders and notes are not used.
- Order: red-flag symptoms, then requests that need a doctor (new medicine, dose change, stopping a course, interactions, diagnosis, pregnancy, a child), then long-lasting or worsening symptoms. Each escalates with the fixed wording and no medicine list.
- Otherwise it matches the message to past conditions, drops medicines blocked by feedback or an allergy, and lists what remains with its source label.
- `guard` runs on every answer before it leaves the server. It rejects a medicine that is not in the history, a changed name or dose, a missing source label or doctor-vs-app line, a medicine list where none belongs, and general information without its disclaimer.
- **Medicine lookup** (added 4 Oct): the user's own records are shown first. A general description comes from the `MedicineInfo` table. If it is missing and `GEMINI_API_KEY` is set, `backend/src/medicine-info/` asks the model once and saves the answer, so each medicine is fetched at most once for all users. Only the medicine name is sent, quoted, never the user's message or data. The model is asked for exactly two facts, what the medicine is usually prescribed for and how to keep it, and only those two fields are read from its reply. It must also say whether the name is a medicine; a non-medicine is declined and not saved. `cleanSummary` removes any sentence that reads like a dose or an instruction and caps the length. Dosage questions are refused by the rules with a fixed "not recommended, visit your doctor" message before any lookup. The text is always shown with a fixed "not advice" line. Chat has its own rate limit because a lookup can cost a model call.

## Trade-offs
- Free tier: Google may use submitted data to improve its products, so only fake prescriptions may be uploaded while the key is on the free tier. Limits are low and change. This must be revisited before real users.
- Both Gemini calls go through `backend/src/common/gemini.ts`, which tries `GEMINI_MODEL` and then `GEMINI_FALLBACK_MODEL` when a model is retired (404), over its free quota (429) or overloaded (500, 503). Defaults are Google's `-latest` aliases, so the model behind them can change without notice.
- The medicine lookup was run against the real service on 4 Oct 2026: one medicine fetched and saved, the repeat answered from the table, a non-medicine declined. Reading a prescription image with Gemini has still only been tested against a mocked response.
- Rule-based matching is literal. It understands "sore throat" and "my throat hurts" but not a symptom described in unusual words; that case gets "nothing in your records, see a doctor", which is the safe side.
- General medicine descriptions are AI-written and unreviewed. This is the one place the product shows medical information that is not from the user's own records, and it moves the scope line in `what-we-do-and-dont.md`. The saved texts must be reviewed by a qualified person before real users see them; the dose filter is a keyword filter and can miss things.
- The keyword lists are short and English only. They were written without medical review and need one before real use.
