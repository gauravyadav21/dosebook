-- S15: an optional reminder on a note (daily, weekly or monthly, at a time). Stored only; the phone schedules it.
CREATE TYPE "NoteReminderFrequency" AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY');

ALTER TABLE "Note"
  ADD COLUMN "reminderFrequency" "NoteReminderFrequency",
  ADD COLUMN "reminderTime" TEXT,
  ADD COLUMN "reminderWeekday" INTEGER,
  ADD COLUMN "reminderDay" INTEGER;
