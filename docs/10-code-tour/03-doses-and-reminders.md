# Tour 3: doses and reminders

Follows: a confirmed schedule becomes today's list of doses; you mark one taken; and the phone reminds you.

Key idea: **reminders are not stored anywhere.** The server stores the schedule (what was confirmed) and the marks (what you did). Today's list and the phone's notifications are worked out from those two each time.

## What is stored
`backend/prisma/schema.prisma`:
- `Schedule`: one per medicine. `slots` (MORNING, NOON, EVENING, NIGHT), `times` (clock times, own reminders only), `food`, `dosesPerDay`, `courseDays` (empty for an own reminder with no end), `startDate`, `stoppedOn`.
- `DoseLog`: one row per marked dose: medicine, date, slot, TAKEN or SKIPPED. Unique on (medicine, date, slot), so marking again updates the row.

Dates are text like `2026-10-05`, not timestamps, so a day never shifts between the phone's time zone and the server's.

## Path A: today's list
1. **`mobile/lib/features/today/today_screen.dart`.** `Loader` calls `api.today(date)` with the phone's own date, and `api.ownReminders()`.
2. **`backend/src/doses/doses.controller.ts`, `today`.** Loads your schedules and today's marks, then for each schedule that is due today lists one dose per slot, attaching the mark if there is one. `origin` is `AS_PRESCRIBED` for a prescription medicine and `YOUR_REMINDER` for your own.
3. **`backend/src/doses/doses.logic.ts`.** Four small pure functions with no database in them:
   - `endDateExclusive`: the first day with no dose. The earlier of "start + course length" and the day you stopped.
   - `isDueOn`: is this date inside the course?
   - `dailySlots`: the slots in day order, then clock times.
   - `totalDoses`: planned doses for the whole course, shortened if stopped early. Used for "Doses taken: 2 of 15".
4. **`backend/src/common/slots.ts`, `slotGroupOf`.** Puts a clock time under a part of the day (`21:30` under Night) so own reminders sit with the named slots.
5. **Back in `today_screen.dart`.** Groups doses by part of day and draws a `DoseRow` (`mobile/lib/widgets/cards.dart`) for each. An own reminder shows "Your reminder · Self-added" and an edit icon; a prescribed dose shows "As prescribed" and no edit icon.

## Path B: marking a dose
1. **`today_screen.dart`, `mark`.** Calls `api.markDose`, wrapped in `guarded` so a server error is shown. Then syncs reminders. It does not reload the list itself: the successful request bumps the session's revision and `Loader` reloads (Tour 5).
2. **`doses.controller.ts`, `mark`.** Finds the schedule by medicine id and your user id (someone else's is 404). Refuses with 400 if that date is outside the course or that slot is not in the schedule. Then `upsert`: create the mark, or change it if one exists.
3. **Adherence.** `backend/src/prescriptions/prescriptions.views.ts` counts TAKEN marks per medicine (`_count.doseLogs`) and divides by `totalDoses`. That is the "Doses taken" line on the timeline.

## Path C: the phone's notifications
1. **When it runs.** `session.reminders.sync(api)` is called when the app opens (`mobile/lib/features/home/home_shell.dart`), after a confirm, after marking a dose, after editing or stopping a course, and after changing an own reminder.
2. **`mobile/lib/reminders/reminders.dart`, `LocalReminders.sync`.** Asks the server for active schedules (`GET /doses/schedules`) and today's doses, builds the set of doses already marked, cancels every pending notification, then schedules the new plan. Any error is caught and logged: reminders are best effort, the Today list is the source of truth.
3. **`mobile/lib/reminders/reminder_plan.dart`, `planReminders`.** A pure function, which is why it can be tested without a phone. For the next 3 days, for each schedule and slot: skip if before the start or on/after the end, skip if already marked, work out the clock time (`slotTimes`: 8:00, 13:00, 18:00, 21:00, or the own time), and add two notifications: one at the dose time and a follow-up 30 minutes later. Times already past are dropped. The result is sorted and cut to the nearest 60, because Android limits pending alarms.
4. **Back in `reminders.dart`.** Each planned item becomes a `zonedSchedule` call with an inexact alarm, which needs no special permission but may arrive a few minutes late.
5. **`Session.signOut`** calls `reminders.clear()` so the next person on the phone gets none of yours.

## Editing and stopping a course
- **`backend/src/medicines/medicines.controller.ts`**: `editSchedule` replaces slots, food timing and length (prescription medicines only); `stop` sets `stoppedOn`. Earlier marks stay.
- **`mobile/lib/features/timeline/prescription_screen.dart`**: the "Edit schedule" and "Stop reminders" buttons, shown only while a course is active.
- Own reminders: **`backend/src/own-reminders/own-reminders.controller.ts`** and **`mobile/lib/features/today/own_reminder_screen.dart`**.

## Tests that prove it
- `backend/src/doses/doses.logic.spec.ts`: course end across month and year ends, stop before the end, open-ended reminders.
- `backend/test/doses.e2e-spec.ts`: "has doses on every day of the course and none before or after", "creates no doses from an unconfirmed upload", "stops a course: no dose is due from the stop date on, earlier marks stay", "cannot read or mark another user's doses".
- `mobile/test/logic_test.dart`: "plans a reminder at each slot and one follow-up 30 minutes later", "plans nothing for a dose already marked taken or skipped", "stops when the course length is reached".

## Agent defaults to question
- Slot times default to 8:00, 13:00 and 20:00; the user can change each one (S14). Changing a time applies at once to doses not yet marked today; a dose already marked today keeps its mark, moved to the new time (see the note under Decisions in S14).
- Note reminders (S15) repeat on the phone on their own (daily, weekly, monthly); only the next 3 days of dose reminders are planned.
- Only 3 days and 60 notifications are planned; if the app is not opened for longer, reminders stop until it is.
- The follow-up fires without asking the server, so a dose marked on another device could still get one.
- Notification timing has never been checked on a device.

## Things to try
1. In `reminder_plan.dart`, change `followUpDelay` to 10 minutes. Run `flutter test`. Which test fails, and what does its name tell you?
2. In `doses.logic.ts`, change `date < end` to `date <= end` in `isDueOn`. Run `npm test`. Read the failing case.
3. On the emulator, mark a dose, then find its row in `DoseLog` with Prisma Studio. Mark it the other way and watch the same row change.

## Check your understanding
1. Where is "remind me at 8:00 tomorrow" stored?
2. Why is `planReminders` a plain function with no plugin calls in it?
3. What stops you marking a dose for a medicine whose course ended last week?
4. How does the timeline know "2 of 15"?

Answers: (1) Nowhere. The phone works it out from the schedule and schedules a local notification; the server only has the schedule and the marks. (2) So it can be unit-tested without a device, and so the rule is in one readable place. (3) `mark` checks `isDueOn` and the slot list and answers 400. (4) TAKEN rows counted per medicine, over `totalDoses` from the schedule.
