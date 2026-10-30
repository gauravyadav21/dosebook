# Data model

Source of truth: `backend/prisma/schema.prisma`. Migrations in `backend/prisma/migrations/`.

Every table except `MedicineInfo` has a `userId`. Every query filters on it, so a record that belongs to another user looks the same as a record that does not exist (404).

| Model | Holds | Notes |
|---|---|---|
| User | email, password hash, acknowledged wording version, profile (name, date of birth, sex, height, weight, blood group, emergency contact, long-term conditions) | Password hashed with scrypt and a random salt. Profile fields are optional and are only stored and shown |
| Document | uploaded file metadata, storage path, status, raw extraction | `extraction` is only shown for review; nothing reads it as confirmed data |
| Doctor | name, specialty, registration number, phone, availability | One card per doctor per user. Unique on (user, registration number) |
| Prescription | condition, date, link to document and doctor | Created only by Confirm. Deleting a doctor sets `doctorId` to null and keeps the prescription |
| Medicine | name, dose, frequency, duration, feedback, source | `source` is PRESCRIPTION or SELF. SELF rows are the user's own reminders; they have no prescription and are not used by chat |
| Schedule | slots, clock times, food timing, doses per day, course length, start date, stop date | One per medicine. `slots` are named times of day taken at their default time; `times` are clock times the user chose instead (S14) or, for own reminders, any times. An open-ended course is for own reminders only |
| DoseLog | medicine, date, slot, TAKEN or SKIPPED | One row per dose; marking again updates it |
| Allergy | name | Unique per user, compared case-insensitively |
| Note | free text, optional reminder (frequency, time, weekday or day of month) | The user's open notes. Nothing reads the text. The reminder is stored only; the phone schedules it (S15) |
| MedicineInfo | medicine name, what it is usually prescribed for (`summary`), how to keep it (`storage`), source | **Shared, not per user.** Holds no user id and nothing from a user's message except the medicine name. Filled once per medicine from a model, then reused |

## Choices
- **Calendar dates are strings** (`YYYY-MM-DD`), not timestamps. A prescription date or a dose day must not shift when the phone and the server are in different time zones. The phone sends its own local date.
- **Feedback is a column on Medicine**, not a table. One current value per medicine is all the stories need.
- **Dose text is free text.** The app stores what the user confirmed or typed and never parses, corrects or computes a dose.
- **Reminders are not stored.** The server stores the schedule and the marks. Today's list and the phone's notifications are computed from them.
- **Slots**: MORNING, LUNCH, DINNER, at 08:00, 13:00 and 20:00 unless the user chose another time (S14). A chosen time is stored as `HH:mm` in `Schedule.times` and belongs to the part of the day it falls in (before 11:00 morning, before 16:00 lunch, otherwise dinner); a medicine has up to twelve doses a day, no two at the same clock time. `DoseLog.slot` holds the slot name or the chosen time.
- **Note reminders** (S15): five nullable columns on `Note`. All null means none. Frequency is ONCE (with a date), DAILY, WEEKLY (weekday 1 Monday to 7) or MONTHLY (day 1 to 28).
- **Uploaded files** are on disk by default (`Document.storagePath`). With `FILE_STORAGE=database` the bytes are in `DocumentBlob`, one row per document, deleted with it; `storagePath` is then empty (ADR 0005).

## Course maths
A dose is due on date `d` when `startDate <= d < end`, where `end` is the earlier of `startDate + courseDays` and the stop date. Planned doses for a course are days times doses per day, shortened when stopped early. Code: `backend/src/doses/doses.logic.ts`, tests beside it.
