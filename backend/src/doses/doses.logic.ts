import { addDays, diffDays } from '../common/dates.js';
import { SLOTS } from '../common/slots.js';

export interface ScheduleLike {
  slots: string[];
  times: string[];
  courseDays: number | null;
  startDate: string;
  stoppedOn: string | null;
}

/** First date on which no dose is due: the earlier of course end and the day the user stopped. Null = open ended. */
export function endDateExclusive(s: ScheduleLike): string | null {
  const courseEnd = s.courseDays === null ? null : addDays(s.startDate, s.courseDays);
  if (courseEnd && s.stoppedOn) return courseEnd < s.stoppedOn ? courseEnd : s.stoppedOn;
  return courseEnd ?? s.stoppedOn;
}

export function isDueOn(s: ScheduleLike, date: string): boolean {
  if (date < s.startDate) return false;
  const end = endDateExclusive(s);
  return end === null || date < end;
}

/** Dose times within one day: named slots in day order, then clock times. */
export function dailySlots(s: ScheduleLike): string[] {
  const named = SLOTS.filter((slot) => s.slots.includes(slot));
  return [...named, ...[...s.times].sort()];
}

/** Planned doses over the whole course, shortened if the user stopped early. Null for open-ended reminders. */
export function totalDoses(s: ScheduleLike): number | null {
  if (s.courseDays === null) return null;
  const end = endDateExclusive(s) as string;
  const days = Math.max(0, Math.min(s.courseDays, diffDays(s.startDate, end)));
  return days * dailySlots(s).length;
}
