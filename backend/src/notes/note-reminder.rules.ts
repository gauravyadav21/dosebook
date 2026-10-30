import { isCalendarDate } from '../common/dates.js';

export type NoteReminderFrequency = 'ONCE' | 'DAILY' | 'WEEKLY' | 'MONTHLY';

/** A reminder on a note, as the app sends and receives it (S15). */
export interface NoteReminder {
  frequency: NoteReminderFrequency;
  /** Clock time "HH:mm". */
  time: string;
  /** 1 (Monday) to 7 (Sunday); weekly only. */
  weekday?: number;
  /** 1 to 28; monthly only. */
  dayOfMonth?: number;
  /** "YYYY-MM-DD"; one-time only. */
  date?: string;
}

export const MAX_DAY_OF_MONTH = 28;

/** The reminder columns of a Note row. All null means no reminder. */
export interface ReminderColumns {
  reminderFrequency: NoteReminderFrequency | null;
  reminderTime: string | null;
  reminderWeekday: number | null;
  reminderDay: number | null;
  reminderDate: string | null;
}

/** Why a reminder cannot be saved, or null when it can. One-time needs a date and a time; daily only a time; weekly adds a weekday;
 *  monthly a day (1 to 28, so every month has it). Fields that do not belong to the frequency are rejected, not ignored.
 *  Whether a one-time date is still ahead is for the phone to say: the server does not know the user's time zone. */
export function reminderProblem(r: NoteReminder): string | null {
  if (r.frequency === 'ONCE') {
    if (typeof r.date !== 'string' || !isCalendarDate(r.date)) return 'A one-time reminder needs a date as YYYY-MM-DD';
  } else if (r.date != null) {
    return 'A date is only for one-time reminders';
  }
  if (r.frequency === 'WEEKLY') {
    if (!Number.isInteger(r.weekday) || (r.weekday as number) < 1 || (r.weekday as number) > 7) {
      return 'A weekly reminder needs a weekday from 1 (Monday) to 7 (Sunday)';
    }
  } else if (r.weekday != null) {
    return 'A weekday is only for weekly reminders';
  }
  if (r.frequency === 'MONTHLY') {
    if (!Number.isInteger(r.dayOfMonth) || (r.dayOfMonth as number) < 1 || (r.dayOfMonth as number) > MAX_DAY_OF_MONTH) {
      return `A monthly reminder needs a day of the month from 1 to ${MAX_DAY_OF_MONTH}`;
    }
  } else if (r.dayOfMonth != null) {
    return 'A day of the month is only for monthly reminders';
  }
  return null;
}

export function toReminderColumns(r: NoteReminder | null): ReminderColumns {
  if (!r) return { reminderFrequency: null, reminderTime: null, reminderWeekday: null, reminderDay: null, reminderDate: null };
  return {
    reminderFrequency: r.frequency,
    reminderTime: r.time,
    reminderWeekday: r.frequency === 'WEEKLY' ? (r.weekday ?? null) : null,
    reminderDay: r.frequency === 'MONTHLY' ? (r.dayOfMonth ?? null) : null,
    reminderDate: r.frequency === 'ONCE' ? (r.date ?? null) : null,
  };
}

export function toReminderView(c: ReminderColumns): NoteReminder | null {
  if (!c.reminderFrequency || !c.reminderTime) return null;
  return {
    frequency: c.reminderFrequency,
    time: c.reminderTime,
    ...(c.reminderWeekday !== null ? { weekday: c.reminderWeekday } : {}),
    ...(c.reminderDay !== null ? { dayOfMonth: c.reminderDay } : {}),
    ...(c.reminderDate !== null ? { date: c.reminderDate } : {}),
  };
}
