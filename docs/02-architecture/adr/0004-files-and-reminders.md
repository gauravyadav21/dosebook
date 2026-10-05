# ADR 0004: File storage and reminders

Status: accepted. Date: 2026-10-04.

## Context
Uploaded prescriptions must be stored. Doses must be reminded on the phone. Queues, push services and object storage were ruled out in ADR 0001.

## Decision

### Files
- Stored on the server's disk under `UPLOAD_DIR/<userId>/<random>.<ext>`. The original file name is kept only as a label in the database and never becomes part of a path.
- Type is decided from the file's first bytes (JPEG, PNG, PDF). The name and the client's MIME type are not trusted. Limit 10 MB.
- A file is served only through an authenticated route that checks the owner.

### Reminders
- The server stores confirmed schedules and dose marks. It sends no push messages.
- The phone asks for active schedules and schedules local notifications: one at the dose time and one follow-up 30 minutes later. Marking a dose, confirming a prescription, editing or stopping a course, and opening the app all rebuild the plan. Signing out clears it.
- Only the nearest 60 notifications over the next 3 days are scheduled, because Android limits pending alarms per app.
- Inexact alarms are used, so no special alarm permission is needed. A reminder can arrive a few minutes late.

## Trade-offs
- Local disk does not survive a redeploy on most free hosts. Object storage is needed before a hosted demo keeps files.
- Files are not encrypted at rest by the app.
- If the app is not opened for more than 3 days, notifications stop until it is opened again. The Today list is always correct.
- The follow-up fires on the phone without checking the server, so a dose marked on another device could still get a follow-up.
- Slot times (8:00, 13:00, 18:00, 21:00) are fixed in the app; the user cannot move them yet.
- Reminders have been exercised by unit tests on the planning logic only, not timed on a device.
