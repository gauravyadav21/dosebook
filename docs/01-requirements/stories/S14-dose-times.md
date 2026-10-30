# S14: Choose the time of each dose
As a patient I can set the clock time for each time of day a medicine is taken, and if I set nothing the app uses a sensible default, so reminders arrive when I actually take it.

Status: **built 8 Oct 2026** (backend 250 unit, 232 e2e; app 213 tests; checked on the Pixel emulator). Replaces the fixed times in S6.

## The three times of day
| Slot | Default time |
|---|---|
| Morning | 08:00 |
| Lunch | 13:00 |
| Dinner | 20:00 |

These replace Morning, Noon, Evening and Night (8:00, 13:00, 18:00, 21:00). A medicine has up to twelve doses a day: the three times of day above, and extra times the user adds ("Add a time"), plus before or after food as now.

## Acceptance criteria
- Given the schedule screen (confirm after upload, and edit schedule), there is one chip per time of day that always shows its time ("Morning 8:00 am"); when the user taps it, then that slot is selected and a pencil appears on the chip. There are no separate time chips and no quick course-length chips.
- Given a time-of-day chip, when the user selects it, then the time picker opens at once, starting at the default time; cancelling keeps the default, choosing another time sets it. Deselecting does not open the picker. The pencil on a chosen chip opens the picker again later. Choosing the default time again goes back to the default.
- Given "Add a time", the user picks a clock time and it appears as an extra dose with a remove icon; tapping it changes the time.
- Given the user does not touch any time, when they confirm, then the default times are used and the schedule is saved with named slots only.
- Given the user changes a time, when they confirm, then the dose is due at the chosen time every day of the course, in Today and in the phone reminder (S6), and the follow-up still fires 30 minutes later.
- Given a dose at any clock time, then Today groups it by the part of the day (before 11:00 Morning, 11:00 to 15:59 Lunch, 16:00 or later Dinner), so a chosen 14:00 sits under Lunch and several doses may share a group. Two doses at the same clock time are not allowed (a named slot counts at its default time); the screen says so and keeps Confirm disabled.
- Given the Doses per day field, it is a number the user can type (1 to 12), like Course length. Until the user types one, it follows how many times are chosen. Confirm stays disabled until the number matches the times chosen, and the screen says how many to add or remove.
- Given a schedule saved before this story with Noon, Evening or Night, then it still works after the change: Noon becomes Lunch (13:00), Evening and Night become Dinner (20:00); a medicine that had both Evening and Night keeps one Dinner dose, and its doses per day drops by one. The user sees the new times.
- Given the user edits a schedule that has custom times, then the editor shows each custom time, not the defaults.
- Given a time change on a schedule, then pending phone reminders are rescheduled (S6); doses already marked today keep their mark.
- Own reminders (S7) are unchanged: any clock time, any number.
- Before or after food, course length and start date behave as before. Doses per day equals the number of selected slots.
- Negative: no dose at all, more than twelve, a slot name other than MORNING, LUNCH or DINNER (including the old NOON, EVENING, NIGHT), a time that is not HH:mm, two doses at the same clock time, or doses per day that does not match the number of times -> 400.
- Negative: no token or an expired token -> 401. User A cannot read or change user B's schedule -> 404.
- Negative: network failure while saving -> the screen keeps what the user entered, shows the server error or "Could not reach the server" and Try again; nothing is half-saved.

## API changes (`docs/02-architecture/openapi.json`, regenerated from the code; the project has no hand-written openapi.yaml)
- `ScheduleDto` (used by `POST /documents/:id/confirm` per medicine and `PATCH /medicines/:id/schedule`):
  - `slots`: array of `MORNING | LUNCH | DINNER`, the slots taken at their default time. May be empty only if `times` is not.
  - `times` (new, optional): array of `"HH:mm"`, slots taken at a time the user chose.
  - `dosesPerDay`: must equal `slots.length + times.length`, between 1 and 12.
  - No two entries at the same clock time (a named slot counts at its default time).
- Responses (schedule views, Today, timeline) return `slots` and `times` the same way; Today groups each dose by `MORNING | LUNCH | DINNER` (`group`).
- Errors: 400 with the existing validation message list; 401; 404.

## Data-model changes
- No new columns: `Schedule.slots` (named) and `Schedule.times` ("HH:mm") already exist; `times` stops being "own reminders only" in the comment and in `data-model.md`.
- Slot value set changes to MORNING, LUNCH, DINNER in `common/slots.ts`; `slotGroupOf` thresholds change as in the table above.
- Migration rewrites existing `Schedule.slots` (NOON to LUNCH, EVENING and NIGHT to DINNER, de-duplicated, `dosesPerDay` recomputed) and `DoseLog.slot` with the same mapping (on a clash for the same medicine and date, keep the status of the later `markedAt`).
- Mobile: default times move from `reminder_plan.dart` into one shared place used by the schedule screen and the planner.

## Decisions (participant, 8 Oct 2026: "recommended for all")
1. A time change applies from tomorrow; today's dose keeps its old time and any mark on it.
   **Built differently, to be confirmed by the participant:** the schedule keeps no history of earlier times, so "from tomorrow" would need a new table. Instead a change applies at once to doses not yet marked today, and a dose already marked today keeps its mark, moved to the new time of that part of the day (`PATCH /medicines/:id/schedule`, tested in `doses.e2e-spec.ts`). Nothing is lost; the only difference is that today's unmarked dose moves too.
2. A time is grouped by its clock time; Morning set to 14:00 counts as Lunch. **Revised the same day by the participant:** several doses may share a group, so Doses per day can be 2, 5, 10 and so on (up to 12); the rule "one dose per part of the day" is gone.
3. Old Evening plus Night merge into one Dinner dose; demo data only.
4. Chat recall wording is unchanged.
