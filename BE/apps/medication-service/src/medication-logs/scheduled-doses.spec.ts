import { describe, expect, it } from 'vitest';
import { scheduledDoseInstants } from './scheduled-doses.js';

describe('scheduledDoseInstants', () => {
  it('keeps only the requested weekdays inside the prescription dates', () => {
    const instants = scheduledDoseInstants({
      startDate: '2026-10-05',
      endDate: '2026-10-11',
      reminderTime: '08:00:00',
      daysOfWeek: [1],
    });

    expect(instants).toEqual([new Date('2026-10-05T01:00:00.000Z')]);
  });

  it('uses thirty days when the prescription has no end date', () => {
    const instants = scheduledDoseInstants({
      startDate: '2026-10-01',
      endDate: null,
      reminderTime: '19:00:00',
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    });

    expect(instants).toHaveLength(30);
    expect(instants[0]).toEqual(new Date('2026-10-01T12:00:00.000Z'));
    expect(instants.at(-1)).toEqual(new Date('2026-10-30T12:00:00.000Z'));
  });
});
