import { clockTimeOf } from '../doses/doses.logic.js';

/** Most doses a day a prescribed schedule can have. */
export const MAX_DOSES_PER_DAY = 12;

/** Why a prescribed schedule cannot be saved, or null when it can (S14). Slots are named times of day taken at their default
 *  time; times are clock times the user chose, for a slot or as extra doses. Doses per day must equal how many were chosen,
 *  and no two may fall at the same clock time. Several doses may fall in one part of the day. */
export function scheduleProblem(slots: string[], times: string[], dosesPerDay: number): string | null {
  const count = slots.length + times.length;
  if (count < 1) return 'Choose at least one time of day';
  if (count > MAX_DOSES_PER_DAY) return `Choose at most ${MAX_DOSES_PER_DAY} times a day`;
  if (dosesPerDay !== count) return 'Doses per day must match the number of times chosen';
  const clocks = new Set([...slots, ...times].map(clockTimeOf));
  if (clocks.size !== count) return 'Two doses are at the same time';
  return null;
}
