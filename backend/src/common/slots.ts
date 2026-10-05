export const SLOTS = ['MORNING', 'NOON', 'EVENING', 'NIGHT'] as const;
export type Slot = (typeof SLOTS)[number];

export const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;

/** Which part of the day a clock time belongs to, so own reminders group with the named slots in Today. */
export function slotGroupOf(slotOrTime: string): Slot {
  if ((SLOTS as readonly string[]).includes(slotOrTime)) return slotOrTime as Slot;
  const hour = Number(slotOrTime.slice(0, 2));
  if (hour < 11) return 'MORNING';
  if (hour < 16) return 'NOON';
  if (hour < 20) return 'EVENING';
  return 'NIGHT';
}
