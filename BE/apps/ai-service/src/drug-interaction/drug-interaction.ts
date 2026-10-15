export type DrugInteraction = {
  checked: true;
  hasWarning: boolean;
  summary: string;
};

const ALONE = 'Chưa có thuốc khác đang dùng để đối chiếu.';
const EMPTY = 'Không có tên thuốc để kiểm tra tương tác.';
const WARNING_FALLBACK = 'Có dấu hiệu tương tác thuốc. Hãy hỏi bác sĩ hoặc dược sĩ trước khi uống thêm.';
const CLEAR_FALLBACK = 'Không thấy tương tác nguy hiểm giữa các thuốc này.';

export function prepareDrugInteraction(currentNames: unknown, newNames: unknown) {
  const current = medicineLabels(currentNames, 40);
  const incoming = medicineLabels(newNames, 20);
  if (incoming.length === 0) {
    return { action: 'skip' as const, result: result(false, EMPTY) };
  }
  if (current.length === 0 && incoming.length < 2) {
    return { action: 'skip' as const, result: result(false, ALONE) };
  }
  return { action: 'ask' as const, current, incoming };
}

export function parseDrugInteraction(raw: string): DrugInteraction {
  let parsed: unknown;
  try {
    parsed = JSON.parse(extractJson(raw));
  } catch {
    throw new Error('The model did not return an interaction JSON');
  }
  if (typeof parsed !== 'object' || parsed === null) {
    throw new Error('The model did not return an interaction JSON');
  }
  const record = parsed as Record<string, unknown>;
  const hasWarning = record.hasWarning === true
    || (typeof record.hasWarning === 'string' && record.hasWarning.trim().toLowerCase() === 'true');
  const summary = clip(textOf(record.summary)) || (hasWarning ? WARNING_FALLBACK : CLEAR_FALLBACK);
  return result(hasWarning, summary);
}

function result(hasWarning: boolean, summary: string): DrugInteraction {
  return { checked: true, hasWarning, summary };
}

function medicineLabels(value: unknown, limit: number) {
  if (!Array.isArray(value)) {
    return [];
  }
  const seen = new Set<string>();
  const labels: string[] = [];
  for (const entry of value) {
    const label = cleanLabel(entry);
    if (!label) {
      continue;
    }
    const key = label.toLocaleLowerCase('vi');
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    labels.push(label);
    if (labels.length >= limit) {
      break;
    }
  }
  return labels;
}

function cleanLabel(value: unknown) {
  if (typeof value !== 'string') {
    return '';
  }
  return value.replace(/[\u0000-\u001F]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 160);
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

function textOf(value: unknown) {
  if (typeof value !== 'string') {
    return '';
  }
  return value.replace(/\s+/g, ' ').trim();
}

function clip(value: string) {
  return value.length > 400 ? value.slice(0, 400) : value;
}
