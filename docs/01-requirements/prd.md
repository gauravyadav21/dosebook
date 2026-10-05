# PRD: DoseBook

Status: draft for review. Date: 2026-10-04.

**Positioning:** A patient-side companion that makes you more aware of your own medicines: what you took, when, and what worked for you. We recall, we remind, we never prescribe. Patient-side only; there is no doctor mode in the MVP.

## Problem
People repeat doctor visits for minor, recurring illnesses (cold, headache, mild infection) because their past prescriptions are scattered across paper and photos, and they forget what worked.

## User
One user: an adult managing their own minor illnesses and health papers.

## Core journey
1. Upload a prescription (photo or PDF).
2. AI extracts medicines, doses, dates, condition and the prescriber's details (name, phone, registration number, specialty, availability when printed).
3. User reviews and corrects the result, including the dose schedule per medicine: slots (morning, noon, evening, night), before or after food, doses per day and course length. Only confirmed data is saved.
4. Confirmed data appears on a timeline of conditions and medicines, and reminders are set from the confirmed schedule.
5. A "Today" list shows the doses due. The user gets a reminder at each slot, a follow-up if the dose is not marked, and taps taken or skipped.

## Reminders (part of the core journey)
- Created only from user-confirmed schedules, never from raw AI output.
- Mobile: local notifications on the device (no backend push). Web: the in-app Today list, as browser notifications are unreliable.
- Reminder at dose time plus one follow-up if the dose is not marked taken.
- Taken and skipped marks form an adherence log on the timeline.
- Dose and instructions are shown exactly as on the prescription; the app never changes them.

## Notes, own reminders and profile
- **Notes** are open notes: free text only. The app stores them and does nothing else with them.
- **Own reminders**: from Today the user can add a reminder for a medicine they take themselves (name, optional dose in their own words, times). It is shown as "your reminder" and tagged Self-added, never as prescribed. The app never fills in or corrects its dose.
- **Profile**: name, date of birth, sex, height, weight, blood group, emergency contact, long-term conditions, and the allergy list. Stored as the user's own record; the app does not advise from it.
- See stories S7 and S10.

## Doctor contacts
- Every prescription shows its doctor on a Doctor tab: name, specialty, phone, registration number and availability, as confirmed from the prescription.
- One contact card per doctor is created from confirmed prescriptions. A Doctors screen lists the cards, so the user does not search through prescriptions to find a number.
- A card opens every prescription recorded against that doctor.
- The user can call from the card and share the doctor's contact through the phone's share sheet. Sharing sends the doctor's contact only, never the user's conditions, medicines or documents.
- Details are shown as printed and are not verified by the app. No live availability and no appointment booking.
- See story S9.

## Doctor vs app: stated repeatedly
The app reminds the user of the difference between a doctor and itself at every point where it matters, not only in a footer. See [[what-we-do-and-dont]]. Touchpoints: first-run acknowledgement (once, must tap to continue), a persistent line in the chat screen, a short line on every chat answer, the extraction confirm screen ("check against your paper prescription"), own reminders, general medicine information, and every escalation message. Wording is short and consistent; no pop-up spam.

## First open, intro and appearance
The app opens without sign-in (S11). A visitor sees four intro pages on every start until they sign in; the last page states what the app never does, in the same fixed wording as the acknowledgement. The app follows the phone's light or dark mode, and the user can choose System, Light or Dark; the choice stays on the phone (S12).

## Scope limit
The app only works from the user's own history and own notes. It does not do anything that needs a doctor's training or experience: no diagnosis or differential, no judging severity beyond fixed red-flag rules, no new medicines, no dose or course changes, no interaction or contraindication judgements (it says "ask your doctor or pharmacist"). If a request needs that, it escalates.

## Polish feature: "What worked for me" chat
The chat does two things.
1. **Symptom recall.** The user describes a minor symptom. The answer comes only from the user's own confirmed prescriptions: medicines taken for the same condition before, with dose, prescriber and the feedback already recorded. It never suggests anything not in the history. Chat does not ask for feedback; that is given on the prescription.
2. **Medicine lookup.** The user types a medicine name. The answer shows their own records of it and, when available, a short general description. General descriptions are saved in our own table; if one is missing and a model is configured, it is fetched once and saved. They never contain a dose or an instruction and are always marked as not being advice.

Any other request is declined. The app never prescribes: it recalls what a doctor already prescribed to this user.

### Guardrails
See [[what-we-do-and-dont]] for the full recall-vs-prescribe statement, escalation rules and FAQ.

- Recall-only: no new medicines, no dose changes.
- Allergies and "did not work" or "side effect" feedback block re-suggestion.
- Red-flag symptoms (e.g. chest pain, breathing difficulty, high fever, symptoms lasting long) produce "see a doctor" and no medicine list.
- Every answer shows a short doctor-vs-app line. General medicine information always carries its "not advice" line.
- AI extraction is never saved without user confirmation.

## Out of scope (future work)
- Doctor report with charts / PDF export
- Crowd and area-based medicine insights. Needs consented real data, aggregation with minimum group sizes, non-promotional framing and legal review of medicine-promotion and medical-device rules.
- Multi-user / family profiles
- **Measurements log.** A screen to record regular measurements, for example blood sugar before and after meals and blood pressure, and others that need regular tracking. Each entry can carry an uploaded document, and past values can be viewed and fetched when needed. Not built.
- **Email verification at sign-up.** The address typed on the sign-up screen is not checked by sending a link or a code. Asked for as future scope by the participant on 5 Oct 2026.
- **Wider AI help in chat.** Today a model is used only to fetch a general description of one medicine when none is saved. Using AI for broader medicine search or conversation is future work and needs the same safeguards plus medical review.

## How the two AI-shaped features work
- Reading a prescription uses a model (Gemini Flash, free tier) when a key is configured, and a demo reader for the bundled fake samples otherwise. The user can always type the details in. See ADR 0003.
- Chat uses fixed rules over the user's saved data. The only model call is the one-time fetch of a general description for a medicine that is not saved yet, and only the medicine name is sent.

## Non-functional
- Authentication on every route; users can only access their own data.
- Input validation, rate limiting, file type and size limits.
- Fake data only in demo and dev; no real patient data in repo or free AI tiers.
- Android app first. A web build and hosted link for judges are not built yet.

## Success criteria
- A judge can complete upload, confirm and chat in under 3 minutes on the demo link.
- Chat refuses or redirects on red-flag and allergy cases (covered by tests).
- Extraction accuracy on the fake test set is measured and documented in `docs/06-qa/qa-strategy.md`.
