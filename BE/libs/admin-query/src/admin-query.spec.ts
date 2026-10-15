import { describe, expect, it } from 'vitest';
import { countsFor, escapeRegex, likePattern, pageWindow, vietnamRange } from './admin-query.js';

describe('admin query helpers', () => {
  it('keeps pages inside the admin list bounds', () => {
    expect(pageWindow(0, 500)).toEqual({ page: 1, limit: 50, skip: 0 });
    expect(pageWindow(2, 10)).toEqual({ page: 2, limit: 10, skip: 10 });
  });

  it('rejects an impossible day and an inverted range', () => {
    expect(vietnamRange('2026-02-31', undefined)).toEqual({ error: 'from is not a real calendar date' });
    expect(vietnamRange('2026-10-15', '2026-10-01')).toEqual({ error: 'The start date is after the end date' });
  });

  it('turns a Vietnam calendar day into a half-open instant window', () => {
    const range = vietnamRange('2026-10-15', '2026-10-15');
    expect(range).toEqual({
      from: new Date('2026-10-15T00:00:00+07:00'),
      toExclusive: new Date('2026-10-16T00:00:00+07:00'),
    });
  });

  it('escapes search text for SQL and regular expressions', () => {
    expect(likePattern('100%_a')).toBe('%100\\%\\_a%');
    expect(escapeRegex('a+b')).toBe('a\\+b');
  });

  it('fills missing statuses with zero', () => {
    expect(countsFor(['TAKEN', 'MISSED'], [{ key: 'TAKEN', count: 4 }])).toEqual({
      total: 4,
      byStatus: { TAKEN: 4, MISSED: 0 },
    });
  });
});
