import { describe, expect, it } from 'vitest';
import { MAX_DOSES_PER_DAY, scheduleProblem } from './schedule.rules.js';

describe('scheduleProblem (S14)', () => {
  it('accepts named slots at their default time', () => {
    expect(scheduleProblem(['MORNING', 'DINNER'], [], 2)).toBeNull();
  });

  it('accepts a chosen time in place of, or next to, a named slot', () => {
    expect(scheduleProblem(['DINNER'], ['07:30'], 2)).toBeNull();
    expect(scheduleProblem([], ['07:30', '13:15', '21:00'], 3)).toBeNull();
  });

  it('accepts several doses in the same part of the day, up to the limit', () => {
    expect(scheduleProblem(['MORNING'], ['09:00', '10:00', '11:30', '12:00'], 5)).toBeNull();
    const ten = Array.from({ length: 10 }, (_, i) => `${String(6 + i).padStart(2, '0')}:00`);
    expect(scheduleProblem([], ten, 10)).toBeNull();
    const max = Array.from({ length: MAX_DOSES_PER_DAY }, (_, i) => `${String(i + 6).padStart(2, '0')}:15`);
    expect(scheduleProblem([], max, MAX_DOSES_PER_DAY)).toBeNull();
  });

  it('needs at least one dose and no more than the limit', () => {
    expect(scheduleProblem([], [], 0)).toMatch(/at least one/i);
    const tooMany = Array.from({ length: MAX_DOSES_PER_DAY + 1 }, (_, i) => `${String(i + 5).padStart(2, '0')}:00`);
    expect(scheduleProblem([], tooMany, tooMany.length)).toMatch(/at most/i);
  });

  it('needs doses per day to match what was chosen', () => {
    expect(scheduleProblem(['MORNING'], ['13:00'], 1)).toMatch(/must match/i);
    expect(scheduleProblem(['MORNING', 'LUNCH'], [], 5)).toMatch(/must match/i);
  });

  it('rejects two doses at the same clock time, a named slot counting at its default time', () => {
    expect(scheduleProblem([], ['07:30', '07:30'], 2)).toMatch(/same time/i);
    expect(scheduleProblem(['MORNING'], ['08:00'], 2)).toMatch(/same time/i);
    expect(scheduleProblem(['MORNING'], ['08:30'], 2)).toBeNull();
  });
});
