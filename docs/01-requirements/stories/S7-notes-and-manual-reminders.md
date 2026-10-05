# S7: Open notes and my own reminders
As a patient I keep free-text notes, and I set my own reminders for medicines I take myself.

Acceptance criteria: notes
- A note is free text only: one text field, nothing else. The user can create, edit and delete notes.
- The text is stored exactly as written. The app does nothing with it: it does not feed chat, Today or the timeline.
- Notes are listed most recently changed first.
- Negative: empty text or text over 5000 characters -> 400.
- Negative: user A cannot read or change user B's notes -> 404.

Acceptance criteria: my own reminders
- From Today, the user can add a reminder for a medicine they take themselves: name (required), optional dose in their own words, and at least one time (morning, noon, evening, night, or a clock time).
- It appears in Today as "Your reminder", tagged Self-added, never as prescribed. Taken and skipped behave as in S6.
- The app never autofills, validates or corrects the dose.
- The user can edit or delete it from Today.
- Own reminders are not part of the prescription timeline or chat.
- Negative: empty name, over-long text, invalid time, no time at all -> 400.
- Negative: user A cannot read or change user B's reminders -> 404. A prescription medicine cannot be changed through this route.
