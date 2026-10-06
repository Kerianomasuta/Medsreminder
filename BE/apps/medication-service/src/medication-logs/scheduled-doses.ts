const APP_TIME_OFFSET = '+07:00';
const OPEN_ENDED_DAYS = 30;

export function scheduledDoseInstants(input: {
  startDate: string;
  endDate: string | null;
  reminderTime: string;
  daysOfWeek: number[];
}): Date[] {
  const endDate = input.endDate ?? addDays(input.startDate, OPEN_ENDED_DAYS - 1);
  const days = new Set(input.daysOfWeek);
  const instants: Date[] = [];

  for (let cursor = input.startDate; cursor <= endDate; cursor = addDays(cursor, 1)) {
    if (!days.has(isoWeekday(cursor))) {
      continue;
    }
    instants.push(new Date(`${cursor}T${input.reminderTime}${APP_TIME_OFFSET}`));
  }

  return instants;
}

function addDays(isoDate: string, days: number) {
  const [year, month, day] = isoDate.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day + days));
  const nextMonth = String(date.getUTCMonth() + 1).padStart(2, '0');
  const nextDay = String(date.getUTCDate()).padStart(2, '0');
  return `${date.getUTCFullYear()}-${nextMonth}-${nextDay}`;
}

function isoWeekday(isoDate: string) {
  const [year, month, day] = isoDate.split('-').map(Number);
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  return weekday === 0 ? 7 : weekday;
}
