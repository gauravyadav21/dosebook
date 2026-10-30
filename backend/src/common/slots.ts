export const SLOTS = ['MORNING', 'LUNCH', 'DINNER'] as const;
export type Slot = (typeof SLOTS)[number];

/** The time a named slot means when the user has not chosen one (S14). */
export const DEFAULT_SLOT_TIMES: Record<Slot, string> = { MORNING: '08:00', LUNCH: '13:00', DINNER: '20:00' };

export const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;

/** Which part of the day a clock time belongs to, so chosen times and own reminders group with the named slots in Today. */
export function slotGroupOf(slotOrTime: string): Slot {
  if ((SLOTS as readonly string[]).includes(slotOrTime)) return slotOrTime as Slot;
  const hour = Number(slotOrTime.slice(0, 2));
  if (hour < 11) return 'MORNING';
  if (hour < 16) return 'LUNCH';
  return 'DINNER';
}
