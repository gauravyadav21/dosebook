import { slotGroupOf } from '../common/slots.js';
import { dailySlots, endDateExclusive, isDueOn, type ScheduleLike, totalDoses } from './doses.logic.js';

const course = (overrides: Partial<ScheduleLike> = {}): ScheduleLike => ({
  slots: ['NIGHT', 'MORNING'],
  times: [],
  courseDays: 5,
  startDate: '2026-10-01',
  stoppedOn: null,
  ...overrides,
});

describe('endDateExclusive', () => {
  it('is the day after the last course day', () => {
    expect(endDateExclusive(course())).toBe('2026-10-06');
  });
  it('crosses month and year ends', () => {
    expect(endDateExclusive(course({ startDate: '2026-12-30', courseDays: 5 }))).toBe('2027-01-04');
  });
  it('is the stop date when the user stopped early', () => {
    expect(endDateExclusive(course({ stoppedOn: '2026-10-03' }))).toBe('2026-10-03');
  });
  it('ignores a stop after the course already ended', () => {
    expect(endDateExclusive(course({ stoppedOn: '2026-11-01' }))).toBe('2026-10-06');
  });
  it('is open ended for an own reminder, until stopped', () => {
    expect(endDateExclusive(course({ courseDays: null }))).toBeNull();
    expect(endDateExclusive(course({ courseDays: null, stoppedOn: '2026-10-09' }))).toBe('2026-10-09');
  });
});

describe('isDueOn', () => {
  it.each([
    ['2026-09-30', false],
    ['2026-10-01', true],
    ['2026-10-05', true],
    ['2026-10-06', false],
  ])('on %s is %s', (date, due) => {
    expect(isDueOn(course(), date)).toBe(due);
  });
  it('is not due on or after the stop date', () => {
    const stopped = course({ stoppedOn: '2026-10-03' });
    expect(isDueOn(stopped, '2026-10-02')).toBe(true);
    expect(isDueOn(stopped, '2026-10-03')).toBe(false);
  });
  it('stays due indefinitely for an open-ended reminder', () => {
    expect(isDueOn(course({ courseDays: null }), '2030-01-01')).toBe(true);
  });
});

describe('dailySlots', () => {
  it('orders named slots by time of day, then clock times', () => {
    expect(dailySlots(course({ slots: ['NIGHT', 'MORNING', 'NOON'], times: ['21:30', '07:15'] }))).toEqual([
      'MORNING',
      'NOON',
      'NIGHT',
      '07:15',
      '21:30',
    ]);
  });
});

describe('totalDoses', () => {
  it('is days times doses per day', () => {
    expect(totalDoses(course())).toBe(10);
  });
  it('shrinks when the course is stopped early', () => {
    expect(totalDoses(course({ stoppedOn: '2026-10-03' }))).toBe(4);
  });
  it('is zero when stopped before the first day', () => {
    expect(totalDoses(course({ stoppedOn: '2026-09-20' }))).toBe(0);
  });
  it('is unknown for an open-ended reminder', () => {
    expect(totalDoses(course({ courseDays: null }))).toBeNull();
  });
});

describe('slotGroupOf', () => {
  it.each([
    ['MORNING', 'MORNING'],
    ['06:00', 'MORNING'],
    ['10:59', 'MORNING'],
    ['11:00', 'NOON'],
    ['15:59', 'NOON'],
    ['16:00', 'EVENING'],
    ['20:00', 'NIGHT'],
    ['23:59', 'NIGHT'],
  ])('%s belongs to %s', (slot, group) => {
    expect(slotGroupOf(slot)).toBe(group);
  });
});
