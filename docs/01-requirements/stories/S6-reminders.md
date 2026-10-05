# S6: Dose reminders
As a patient I get reminded at the right times so I take each dose as prescribed.

Acceptance criteria
- Given a confirmed schedule, a reminder is scheduled for each slot of each day of the course.
- Given a dose not marked taken or skipped after the follow-up delay, a second reminder fires once.
- Given the user marks taken or skipped, no follow-up fires and the mark appears in the adherence log.
- Given unconfirmed or edited-but-unsaved data, no reminder is created.
- Given the course length is reached, reminders stop.
- Given the user edits or stops a course, pending reminders are rescheduled or cancelled.
- Today list shows doses due, grouped by slot, with medicine, dose and before/after-food note from the prescription.
- Negative: invalid slot, zero or negative dose count, course length over a sane limit -> 400.
- Negative: user A cannot read or change user B's schedule or dose log -> 404.
- Web: reminders are visible in the Today list even where browser notifications are unavailable.
