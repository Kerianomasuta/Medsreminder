const UNITS = ['VIEN', 'GOI', 'CHAI'] as const;
const ALL_WEEK = [1, 2, 3, 4, 5, 6, 7];

export type DraftSchedule = {
  reminderTime: string;
  daysOfWeek: number[];
};

export type DraftItem = {
  name: string;
  genericName?: string;
  unit: (typeof UNITS)[number];
  dosagePerTime: number;
  currentStock?: number;
  instructions?: string;
  schedules: DraftSchedule[];
};

export type PrescriptionDraft = {
  title: string;
  doctorName: string | null;
  prescriptionCode: string | null;
  startDate: string | null;
  endDate: string | null;
  items: DraftItem[];
};

export function parsePrescriptionDraft(raw: string): PrescriptionDraft {
  let parsed: unknown;
  try {
    parsed = JSON.parse(extractJson(raw));
  } catch {
    throw new Error('The model did not return a prescription JSON');
  }
  if (typeof parsed !== 'object' || parsed === null) {
    throw new Error('The model did not return a prescription JSON');
  }
  const record = parsed as Record<string, unknown>;
  const items = normalizeItems(record.items);
  if (items.length === 0) {
    throw new Error('No medicine line could be read from the prescription photo');
  }
  const title = textOf(record.title) ?? 'Đơn thuốc từ ảnh';
  return {
    title: title.slice(0, 200),
    doctorName: clip(textOf(record.doctorName), 200),
    prescriptionCode: clip(textOf(record.prescriptionCode), 100),
    startDate: dateOf(record.startDate),
    endDate: dateOf(record.endDate),
    items,
  };
}

function extractJson(raw: string) {
  const fenced = raw.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const source = fenced?.[1] ?? raw;
  const start = source.indexOf('{');
  const end = source.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return source.slice(start, end + 1);
  }
  return source.trim();
}

function normalizeItems(value: unknown): DraftItem[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.flatMap((entry) => {
    if (typeof entry !== 'object' || entry === null) {
      return [];
    }
    const item = entry as Record<string, unknown>;
    const name = textOf(item.name);
    if (!name) {
      return [];
    }
    const schedules = normalizeSchedules(item.schedules);
    const genericName = textOf(item.genericName);
    const instructions = textOf(item.instructions);
    const currentStock = wholeNumber(item.currentStock);
    return [{
      name: name.slice(0, 200),
      ...(genericName ? { genericName: genericName.slice(0, 200) } : {}),
      unit: unitOf(item.unit),
      dosagePerTime: doseOf(item.dosagePerTime),
      ...(currentStock === undefined ? {} : { currentStock }),
      ...(instructions ? { instructions: instructions.slice(0, 2000) } : {}),
      schedules: schedules.length > 0 ? schedules : [{ reminderTime: '08:00', daysOfWeek: ALL_WEEK }],
    }];
  });
}

function normalizeSchedules(value: unknown): DraftSchedule[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.flatMap((entry) => {
    if (typeof entry !== 'object' || entry === null) {
      return [];
    }
    const schedule = entry as Record<string, unknown>;
    const reminderTime = timeOf(schedule.reminderTime);
    if (!reminderTime) {
      return [];
    }
    return [{ reminderTime, daysOfWeek: daysOf(schedule.daysOfWeek) }];
  });
}

function unitOf(value: unknown): (typeof UNITS)[number] {
  const text = String(value ?? '').trim().toUpperCase();
  if (text.includes('GOI') || text.includes('GÓI') || text.includes('PACK') || text.includes('SACHET')) {
    return 'GOI';
  }
  if (text.includes('CHAI') || text.includes('BOTTLE') || text.includes('LỌ') || text.includes('LO')) {
    return 'CHAI';
  }
  return 'VIEN';
}

function doseOf(value: unknown) {
  if (typeof value === 'number' && Number.isFinite(value) && value > 0) {
    return Math.round(value * 100) / 100;
  }
  const match = String(value ?? '').match(/(\d+(?:[.,]\d+)?)/);
  if (!match) {
    return 1;
  }
  const amount = Number(match[1].replace(',', '.'));
  return amount > 0 ? Math.round(amount * 100) / 100 : 1;
}

function timeOf(value: unknown) {
  const text = String(value ?? '').trim().toLowerCase();
  const clock = text.match(/^([01]\d|2[0-3]):([0-5]\d)/);
  if (clock) {
    return `${clock[1]}:${clock[2]}`;
  }
  if (text.includes('sáng') || text.includes('sang')) {
    return '08:00';
  }
  if (text.includes('trưa') || text.includes('trua')) {
    return '12:00';
  }
  if (text.includes('chiều') || text.includes('chieu')) {
    return '16:00';
  }
  if (text.includes('tối') || text.includes('toi')) {
    return '20:00';
  }
  return undefined;
}

function daysOf(value: unknown) {
  if (!Array.isArray(value)) {
    return ALL_WEEK;
  }
  const days = [...new Set(value.map(Number).filter((day) => Number.isInteger(day) && day >= 1 && day <= 7))].sort();
  return days.length > 0 ? days : ALL_WEEK;
}

function wholeNumber(value: unknown) {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < 0) {
    return undefined;
  }
  return value;
}

function dateOf(value: unknown) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return null;
  }
  const [year, month, day] = value.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  const real = date.getUTCFullYear() === year
    && date.getUTCMonth() === month - 1
    && date.getUTCDate() === day;
  return real ? value : null;
}

function textOf(value: unknown) {
  if (typeof value !== 'string') {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function clip(value: string | undefined, max: number) {
  return value ? value.slice(0, max) : null;
}
