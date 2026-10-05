# S5: "What worked for me" chat
As a user I describe a minor symptom and get back only what I took before, or I look up a medicine.

The chat does two things and nothing else: symptom recall and medicine lookup.

Acceptance criteria: symptom recall
- Given history for the condition, the answer lists those medicines with dose, prescriber, date, the feedback already recorded, and a disclaimer.
- Chat never asks for feedback. A medicine with none shows "No feedback recorded". Feedback is given on the prescription (S4).
- Given no matching history, the answer says so and suggests seeing a doctor; no medicine is invented.
- Given a medicine marked "did not work", "side effect" or matching an allergy, it is not recalled.
- Given red-flag symptoms, the answer redirects to a doctor and lists no medicines.
- Given a request for a new medicine, stopping a course, pregnancy or a child, the answer escalates to a doctor per `what-we-do-and-dont.md` and lists no medicines.
- Given any question about dosage (how much, how many, how often, a dose change, an amount such as "500 mg"), the answer is: "I can't tell you how much to take. Taking a medicine without a doctor's advice is not recommended. Please visit your doctor." No medicine is listed and no lookup is made.
- The user's own reminders and notes are not part of chat.

Acceptance criteria: medicine lookup
- Given a medicine name ("paracetamol", "what is paracetamol"), the answer shows the user's own records for it: when, for what, dose, doctor, feedback. Records are shown even if the user marked the medicine or is allergic to it; a matching allergy is flagged.
- General information about the medicine is shown when it is saved in our own table. If it is not saved and a model is configured, it is fetched once, saved, and reused for every later lookup by any user. Only the medicine name is sent to the model.
- General information is exactly two facts and nothing else: what the medicine is usually prescribed for, and how to keep (store) it. No dose, frequency, side effects, warnings or interactions. Anything that reads like a dose or an instruction is removed before it is saved; storage is left out when nothing usable comes back. It is always shown with: "General information from an AI model, not checked by a doctor. Not advice. Ask your doctor or pharmacist."
- Given a name that is not a medicine, the request is declined and nothing is saved.
- Given no record and no saved information, the answer says so.

Acceptance criteria: everything else
- Any other request is declined: "I can do two things: show what you took before for a symptom, or look up a medicine. I can't help with anything else."
- Every answer passes a server-side check: no medicine outside the user's history, no changed name or dose, the doctor-vs-app line present, general information only with its disclaimer. A failing answer becomes an escalation.
- Negative: empty or over-long message -> 400. Another user's history never appears.
