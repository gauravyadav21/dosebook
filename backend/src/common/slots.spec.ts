import { describe, expect, it } from 'vitest';
import { DEFAULT_SLOT_TIMES, SLOTS, slotGroupOf } from './slots.js';

describe('slots (S14)', () => {
  it('has three times of day with the agreed default times', () => {
    expect(SLOTS).toEqual(['MORNING', 'LUNCH', 'DINNER']);
    expect(DEFAULT_SLOT_TIMES).toEqual({ MORNING: '08:00', LUNCH: '13:00', DINNER: '20:00' });
  });

  it('groups a clock time by the part of the day', () => {
    expect(slotGroupOf('06:30')).toBe('MORNING');
    expect(slotGroupOf('10:59')).toBe('MORNING');
    expect(slotGroupOf('11:00')).toBe('LUNCH');
    expect(slotGroupOf('15:59')).toBe('LUNCH');
    expect(slotGroupOf('16:00')).toBe('DINNER');
    expect(slotGroupOf('23:45')).toBe('DINNER');
  });

  it('keeps a named slot as it is', () => {
    expect(slotGroupOf('LUNCH')).toBe('LUNCH');
  });
});
