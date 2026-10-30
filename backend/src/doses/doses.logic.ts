import { addDays, diffDays } from '../common/dates.js';
import { DEFAULT_SLOT_TIMES, type Slot } from '../common/slots.js';

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

/** The clock time a dose is due: a chosen time as it is, a named slot at its default time (S14). */
export function clockTimeOf(slotOrTime: string): string {
  return DEFAULT_SLOT_TIMES[slotOrTime as Slot] ?? slotOrTime;
}

/** Dose times within one day in clock order: named slots at their default time, chosen times as given. */
export function dailySlots(s: ScheduleLike): string[] {
  return [...s.slots, ...s.times].sort((a, b) => clockTimeOf(a).localeCompare(clockTimeOf(b)));
}

/** Planned doses over the whole course, shortened if the user stopped early. Null for open-ended reminders. */
export function totalDoses(s: ScheduleLike): number | null {
  if (s.courseDays === null) return null;
  const end = endDateExclusive(s) as string;
  const days = Math.max(0, Math.min(s.courseDays, diffDays(s.startDate, end)));
  return days * dailySlots(s).length;
}
