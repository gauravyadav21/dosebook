# S15: Reminders on notes
As a patient I can attach a reminder to a note, once on a date or repeating daily, weekly or monthly at a time I choose, so I am nudged to do what the note says.

Status: **built 8 Oct 2026** (backend 265 unit, 248 e2e; app 213 tests; weekly reminder saved and its alarm seen scheduled on the Pixel emulator; a reminder actually firing has not been seen). Changes two lines of S7.

## Changes to S7
- S7 says a note is free text only and the app does nothing with it. This story adds one optional thing the app does: a reminder the user asks for on that note. The text is still stored exactly as written, is not read by the app for any other purpose, and does not feed chat, Today or the timeline.

## Acceptance criteria
- Given a note (new or existing), the editor has a "Remind me" row with a switch, off by default. Switching it on, or tapping the row, opens a bottom sheet with every choice; closing the sheet without setting anything leaves the reminder as it was (off, for a new one). The sheet has "Set reminder", and "Remove reminder" when the note already has one.
- Given the sheet, the user chooses how often:
  - Once: on a date (starting tomorrow) at a time. A date and time that have already passed cannot be set.
  - Daily: at a time.
  - Weekly: on a weekday, at a time.
  - Monthly: on a day of the month (1 to 28), at a time.
  The time defaults to 09:00 if the user does not choose one.
- Given the note is saved with a reminder, then the phone shows a notification at the chosen time, repeating until the user turns the reminder off or deletes the note. The notification is titled "Note reminder" and shows the first line of the note.
- Given the note is saved with the switch off, or the reminder is removed later, then no notification fires and any scheduled one is cancelled.
- Given the note is deleted, then its reminder is cancelled.
- Given a note with a reminder, the notes list shows a small bell and the schedule in words ("Weekly, Monday 09:00").
- Given the user edits the text but not the reminder, the reminder stays as it was.
- Given sign-out, note reminders on the phone are cleared with the others (S6).
- A note reminder is not shown in Today and is not a dose: there is no taken or skipped, and no follow-up.
- Negative: one time without a date or with a date that is not a calendar day, a date on any other frequency, weekly without a weekday, monthly without a day, a day outside 1 to 28, a time that is not HH:mm, an unknown frequency, or unknown fields -> 400.
- Negative: empty text or over 5000 characters -> 400 (S7, unchanged).
- Negative: no token or an expired token -> 401. User A cannot read, set or clear a reminder on user B's note -> 404.
- Negative: network failure while saving -> the editor keeps the text and the reminder choices and shows the error; the old reminder stays in force until a save succeeds.
- A visitor (not signed in) adding a note is asked to sign in first (S11), as today.

## API changes (regenerated into `docs/02-architecture/openapi.json`)
- `NoteDto` (`POST /notes`, `PATCH /notes/:id`): add optional `reminder`:
  `{ frequency: "ONCE" | "DAILY" | "WEEKLY" | "MONTHLY", time: "HH:mm", date?: "YYYY-MM-DD" (once only), weekday?: 1..7 (1 = Monday), dayOfMonth?: 1..28 }`.
  On `PATCH`, omitting `reminder` leaves it unchanged; `"reminder": null` removes it.
- Note response (`GET /notes`, `POST`, `PATCH`): add `reminder` (the object above, or `null`).
- Errors: 400, 401, 404 as above. No new routes.

## Data-model changes
- `Note`: add nullable `reminderFrequency` (enum `ONCE | DAILY | WEEKLY | MONTHLY`), `reminderTime` (text "HH:mm"), `reminderWeekday` (int 1 to 7), `reminderDay` (int 1 to 28), `reminderDate` (text "YYYY-MM-DD", once only). All null means no reminder. Two migrations (`note_reminder`, then `note_reminder_once`). The server cannot tell whether a one-time date has passed (it does not know the user's time zone), so the phone checks that.
- No server-side scheduling and no push service. The phone schedules a repeating local notification; the server only stores the choice, so a reinstall or a second phone gets it again after sign-in.
- Mobile: a second notification channel "Notes", a pure function that turns the notes into the notifications to schedule (tested without a phone), and the existing reminder sync also reads the notes.

## Decisions (participant, 8 Oct 2026: "recommended for all")
1. The notification shows the first line of the note.
2. Monthly day is 1 to 28.
3. Weekly takes one weekday.
4. After a phone restart the reminders return when the app is next opened; written under limitations.
5. No exact-alarm permission; a notification may be a few minutes late when the phone is idle.
