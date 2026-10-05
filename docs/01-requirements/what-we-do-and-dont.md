# What the app does and does not do

Single source for FAQ answers, in-app wording, the demo Q&A and the privacy policy. Draft: wording needs legal review before real users (medical-device and medicine-advertising rules vary by country).

## In one sentence
This is a patient-side mode for medical records: it makes people more aware of their own medicines (what they took, when, and what worked).

We **recall** what your own doctors already prescribed you, and remind you to take it as prescribed. We do **not** prescribe, diagnose or treat.

## Recall vs prescribe

| We do (recall) | We do not (prescribe) |
|---|---|
| Store and organise your documents | Diagnose a condition |
| Show medicines a doctor prescribed you before, with dose, prescriber, date and your own feedback | Suggest any medicine that is not in your own history |
| Remind you of doses exactly as written on your prescription | Change a dose, frequency or course length |
| Record what worked or did not work for you | Replace a doctor's consent, examination or follow-up |
| Tell you when something needs a doctor | Judge how serious your condition is beyond simple warning rules |
| Let you keep your own notes and your own reminders, clearly marked self-added | Verify, correct or recommend doses for self-added medicines |
| Show what a medicine you look up is usually prescribed for and how to keep it, marked as general information and not advice | Tell you whether to take it, how much, or whether it suits you. A dosage question gets "not recommended, please visit your doctor" |
| Keep your profile details (height, weight, blood group and so on) as your own record | Judge or advise from those details |
| Say "ask your doctor or pharmacist" about interactions | Judge interactions or contraindications |
| Show your doctor's contact details as printed on your prescription, and let you call or share them | Verify a doctor's registration, show live availability or book appointments |

## What needs a doctor, not us
Anything that needs a doctor's training or experience stays with the doctor: diagnosis or ruling conditions in or out, judging how serious something is beyond fixed warning signs, choosing a new medicine, changing a dose or course, and judging interactions, pregnancy or child dosing. We only work from your own history and your own notes, from your point of view.

## Your own notes and reminders
Notes are free text for you alone; we do nothing with them. You can also set your own reminder for a medicine you take yourself (for example an over-the-counter item). It is marked **Self-added** and "your reminder". We never present it as prescribed and never check or correct its dose.

## Looking up a medicine
When you type a medicine name in chat, we show your own records of it. We may also show two general facts: what the medicine is usually prescribed for, and how to keep it. Nothing else. That text comes from an AI model, is saved so it is fetched only once, and is not checked by a doctor. It never includes a dose or an instruction. If you ask how much or how often to take something, we say that taking a medicine without a doctor's advice is not recommended and ask you to visit your doctor. It is general information, not advice about you. Only the medicine name is sent to the model, never your message or your data. Chat declines anything that is not symptom recall or a medicine lookup.

## Where we remind you of the difference
First-run acknowledgement, a persistent line in chat, a short line on every answer, the prescription confirm screen, own reminders, general medicine information, and every escalation message. Short, consistent wording.

## When we send you to a doctor (escalation)
The app does not answer with medicines when:
- Symptoms are red-flag (for example chest pain, trouble breathing, signs of stroke, severe bleeding, very high fever, fainting, sudden severe pain).
- Symptoms are long-lasting, getting worse, or keep coming back.
- Your history has no matching condition.
- A past medicine is marked "did not work" or "side effect", or matches an allergy.
- The situation involves pregnancy, a child, or an interaction we cannot rule out.
- You ask for something outside your history (a new medicine, a different dose, stopping a course).

The message: "This needs a doctor's attention. I can't prescribe or advise treatment. Please contact your doctor or emergency services." We never tell you to start, change or stop a treatment without a doctor's consent. In an emergency, call your local emergency number.

## FAQ
**Does the app prescribe medicine?** No. Only a doctor can prescribe. The app shows what your doctors prescribed you before.

**Can it tell me what I have?** No. It does not diagnose.

**Why does it suggest a medicine from last time?** Because it is in your own records, with the dose and prescriber from the original prescription. Check with your doctor or pharmacist if anything has changed (new allergy, other medicines, pregnancy).

**The app showed me what a medicine is for. Is that advice?** No. It is a general description from an AI model, not checked by a doctor and not about you. Ask your doctor or pharmacist before taking anything.

**Can I change my dose in the app?** No. Reminders follow the prescription you confirmed. Ask your doctor to change a dose.

**What if the AI reads my prescription wrong?** You review and correct every extracted field before anything is saved or any reminder is set.

**Is this a replacement for visiting a doctor?** No. It reduces repeat paperwork and forgotten history. Serious, new, worsening or lasting symptoms always need a doctor.

**Is the app a medical device?** It is designed as a records and reminder tool, not a diagnostic or treatment tool. This must be confirmed with a regulatory review before public launch.

## Privacy-policy-ready statements (draft)
- We process your documents and health information only to provide your history, reminders and recall of your own medicines.
- When you look up a medicine, only the medicine's name may be sent to an AI model to fetch a general description. Your message, records and identity are not sent.
- We do not use your data to recommend medicines to you or others, and we do not sell or share it for advertising.
- AI reads your uploaded prescriptions to extract text. You confirm the result; nothing is saved without your confirmation.
- Your data is visible only to you. Other users cannot access it.
- When you share a doctor's contact card, only the doctor's name, specialty, phone, registration number and availability are shared. Your conditions, medicines and documents are never included.
- Doctor contact details come from your own prescriptions. We do not verify them and do not add doctors from any other source.
- You can export and delete your data.
- Aggregated or area-based insights are not part of the product. If ever offered, they would need your explicit opt-in, aggregation with minimum group sizes, and legal review.
- Demo and development use fake data only.

## Used in
PRD guardrails, chat refusal and escalation tests (S5), deck "Guardrails" slide, privacy policy, judge Q&A.
