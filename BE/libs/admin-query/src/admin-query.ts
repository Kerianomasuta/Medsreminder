export function pageWindow(page?: number, limit?: number) {
  const safePage = positiveInt(page, 1);
  const safeLimit = Math.min(50, positiveInt(limit, 20));
  return { page: safePage, limit: safeLimit, skip: (safePage - 1) * safeLimit };
}

export function vietnamRange(from?: string, to?: string): { from?: Date; toExclusive?: Date } | { error: string } {
  const start = readDay(from);
  const end = readDay(to);
  if (start === false) {
    return { error: 'from is not a real calendar date' };
  }
  if (end === false) {
    return { error: 'to is not a real calendar date' };
  }
  if (start && end && start.getTime() > end.getTime()) {
    return { error: 'The start date is after the end date' };
  }
  return {
    from: start ?? undefined,
    toExclusive: end ? new Date(end.getTime() + 24 * 60 * 60 * 1000) : undefined,
  };
}

export function likePattern(value?: string) {
  const trimmed = value?.trim().slice(0, 80) ?? '';
  if (!trimmed) {
    return null;
  }
  return `%${trimmed.replace(/[\\%_]/g, '\\$&')}%`;
}

export function escapeRegex(value: string) {
  return value.trim().slice(0, 80).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export function countsFor(keys: readonly string[], rows: { key: string; count: number }[]) {
  const byStatus: Record<string, number> = {};
  for (const key of keys) {
    byStatus[key] = 0;
  }
  let total = 0;
  for (const row of rows) {
    const count = Number.isFinite(row.count) ? row.count : 0;
    total += count;
    if (row.key in byStatus) {
      byStatus[row.key] = count;
    }
  }
  return { total, byStatus };
}

export function numberOrNull(value: unknown) {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function positiveInt(value: number | undefined, fallback: number) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 1) {
    return fallback;
  }
  return Math.floor(value);
}

function readDay(value?: string): Date | null | false {
  if (value === undefined || value.trim() === '') {
    return null;
  }
  const day = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    return false;
  }
  const date = new Date(`${day}T00:00:00+07:00`);
  if (Number.isNaN(date.getTime())) {
    return false;
  }
  const formatted = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
  return formatted === day ? date : false;
}
