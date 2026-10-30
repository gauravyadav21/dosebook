import { describe, expect, it } from 'vitest';
import { reminderProblem, toReminderColumns, toReminderView } from './note-reminder.rules.js';

describe('note reminder rules (S15)', () => {
  it('accepts a daily reminder with a time', () => {
    expect(reminderProblem({ frequency: 'DAILY', time: '09:00' })).toBeNull();
  });

  it('accepts a one-time reminder with a date and a time', () => {
    expect(reminderProblem({ frequency: 'ONCE', time: '09:00', date: '2026-10-12' })).toBeNull();
    expect(reminderProblem({ frequency: 'ONCE', time: '23:59', date: '2028-02-29' })).toBeNull();
  });

  it('accepts a weekly reminder on a weekday and a monthly one on a day of the month', () => {
    expect(reminderProblem({ frequency: 'WEEKLY', time: '07:30', weekday: 1 })).toBeNull();
    expect(reminderProblem({ frequency: 'WEEKLY', time: '07:30', weekday: 7 })).toBeNull();
    expect(reminderProblem({ frequency: 'MONTHLY', time: '18:00', dayOfMonth: 1 })).toBeNull();
    expect(reminderProblem({ frequency: 'MONTHLY', time: '18:00', dayOfMonth: 28 })).toBeNull();
  });

  it.each([
    ['weekly without a weekday', { frequency: 'WEEKLY', time: '09:00' }, /weekday/i],
    ['weekly with a weekday out of range', { frequency: 'WEEKLY', time: '09:00', weekday: 8 }, /weekday/i],
    ['weekly with weekday 0', { frequency: 'WEEKLY', time: '09:00', weekday: 0 }, /weekday/i],
    ['monthly without a day', { frequency: 'MONTHLY', time: '09:00' }, /day of the month/i],
    ['monthly day 29', { frequency: 'MONTHLY', time: '09:00', dayOfMonth: 29 }, /day of the month/i],
    ['monthly day 0', { frequency: 'MONTHLY', time: '09:00', dayOfMonth: 0 }, /day of the month/i],
    ['one time without a date', { frequency: 'ONCE', time: '09:00' }, /date/i],
    ['one time with a date that is not a calendar day', { frequency: 'ONCE', time: '09:00', date: '2026-02-30' }, /date/i],
    ['one time with a badly written date', { frequency: 'ONCE', time: '09:00', date: '12/10/2026' }, /date/i],
    ['one time with a weekday', { frequency: 'ONCE', time: '09:00', date: '2026-10-12', weekday: 1 }, /only for weekly/i],
    ['one time with a day of the month', { frequency: 'ONCE', time: '09:00', date: '2026-10-12', dayOfMonth: 3 }, /only for monthly/i],
    ['daily with a date', { frequency: 'DAILY', time: '09:00', date: '2026-10-12' }, /only for one-time/i],
    ['weekly with a date', { frequency: 'WEEKLY', time: '09:00', weekday: 1, date: '2026-10-12' }, /only for one-time/i],
    ['daily with a weekday', { frequency: 'DAILY', time: '09:00', weekday: 2 }, /only for weekly/i],
    ['daily with a day of the month', { frequency: 'DAILY', time: '09:00', dayOfMonth: 2 }, /only for monthly/i],
    ['weekly with a day of the month', { frequency: 'WEEKLY', time: '09:00', weekday: 2, dayOfMonth: 2 }, /only for monthly/i],
    ['monthly with a weekday', { frequency: 'MONTHLY', time: '09:00', dayOfMonth: 2, weekday: 2 }, /only for weekly/i],
  ] as const)('rejects %s', (_label, reminder, message) => {
    expect(reminderProblem(reminder)).toMatch(message);
  });

  it('stores a reminder in columns and reads it back', () => {
    const columns = toReminderColumns({ frequency: 'WEEKLY', time: '07:30', weekday: 3 });
    expect(columns).toEqual({ reminderFrequency: 'WEEKLY', reminderTime: '07:30', reminderWeekday: 3, reminderDay: null, reminderDate: null });
    expect(toReminderView(columns)).toEqual({ frequency: 'WEEKLY', time: '07:30', weekday: 3 });
  });

  it('stores a one-time reminder with its date and reads it back', () => {
    const columns = toReminderColumns({ frequency: 'ONCE', time: '08:15', date: '2026-11-03' });
    expect(columns).toEqual({
      reminderFrequency: 'ONCE',
      reminderTime: '08:15',
      reminderWeekday: null,
      reminderDay: null,
      reminderDate: '2026-11-03',
    });
    expect(toReminderView(columns)).toEqual({ frequency: 'ONCE', time: '08:15', date: '2026-11-03' });
  });

  it('clears every column for no reminder, and reads that back as null', () => {
    const columns = toReminderColumns(null);
    expect(columns).toEqual({ reminderFrequency: null, reminderTime: null, reminderWeekday: null, reminderDay: null, reminderDate: null });
    expect(toReminderView(columns)).toBeNull();
  });

  it('reads a monthly reminder with its day only', () => {
    expect(toReminderView({ reminderFrequency: 'MONTHLY', reminderTime: '18:00', reminderWeekday: null, reminderDay: 15, reminderDate: null })).toEqual({
      frequency: 'MONTHLY',
      time: '18:00',
      dayOfMonth: 15,
    });
  });
});
