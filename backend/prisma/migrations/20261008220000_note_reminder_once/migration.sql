-- S15: a reminder that fires once, on a date.
ALTER TYPE "NoteReminderFrequency" ADD VALUE 'ONCE';

ALTER TABLE "Note" ADD COLUMN "reminderDate" TEXT;
