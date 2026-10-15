import PDFDocument from 'pdfkit';
import { COMPLIANCE_REPORT_FONT } from './compliance-report.font.js';

export const ON_TIME_MS = 30 * 60 * 1000;
export const MISSED_AFTER_MS = 11 * 60 * 1000;
export const REPORT_DAYS = 30;

export type ComplianceDose = {
  medicineName: string;
  status: string;
  scheduledAt: Date;
  actualTakenAt: Date | null;
  snoozeUntil: Date | null;
};

export type ComplianceMedicineLine = {
  prescriptionId: string;
  title: string;
  doctorName: string | null;
  startDate: string;
  endDate: string | null;
  medicineName: string;
  dosage: string;
  unit: string;
  reminderTime: string | null;
};

export type ComplianceReport = {
  patientName: string;
  from: string;
  to: string;
  generatedAt: Date;
  rate: number | null;
  onTime: number;
  late: number;
  missed: number;
  skipped: number;
  closed: number;
  medicines: Array<{ name: string; onTime: number; missed: number; closed: number; rate: number | null }>;
  recentMisses: Array<{ at: string; medicineName: string }>;
  prescriptions: Array<{
    title: string;
    doctorName: string | null;
    startDate: string;
    endDate: string | null;
    medicines: Array<{ name: string; dosage: string; times: string[] }>;
  }>;
};

type ReportBlock =
  | { kind: 'h1' | 'h2' | 'p'; text: string }
  | { kind: 'table'; rows: string[][] };

export function buildComplianceReport(input: {
  patientName: string;
  from: string;
  to: string;
  now: Date;
  doses: ComplianceDose[];
  lines: ComplianceMedicineLine[];
}): ComplianceReport {
  const counted = input.doses.filter((dose) => !isStillOpen(dose, input.now));
  let onTime = 0;
  let late = 0;
  let missed = 0;
  let skipped = 0;
  const byMedicine = new Map<string, { onTime: number; missed: number; closed: number }>();
  const misses: Array<{ at: Date; medicineName: string }> = [];

  for (const dose of counted) {
    const name = dose.medicineName.trim() || 'Thuốc';
    const bucket = byMedicine.get(name) ?? { onTime: 0, missed: 0, closed: 0 };
    bucket.closed += 1;
    const outcome = outcomeOf(dose);
    if (outcome === 'onTime') {
      onTime += 1;
      bucket.onTime += 1;
    } else if (outcome === 'late') {
      late += 1;
    } else if (outcome === 'skipped') {
      skipped += 1;
    } else {
      missed += 1;
      bucket.missed += 1;
      misses.push({ at: dose.scheduledAt, medicineName: name });
    }
    byMedicine.set(name, bucket);
  }

  const closed = onTime + late + missed + skipped;
  return {
    patientName: clean(input.patientName) || 'Bệnh nhân',
    from: input.from,
    to: input.to,
    generatedAt: input.now,
    rate: rateOf(onTime, closed),
    onTime,
    late,
    missed,
    skipped,
    closed,
    medicines: [...byMedicine.entries()]
      .map(([name, bucket]) => ({ name, ...bucket, rate: rateOf(bucket.onTime, bucket.closed) }))
      .sort((left, right) => left.name.localeCompare(right.name, 'vi')),
    recentMisses: misses
      .sort((left, right) => right.at.getTime() - left.at.getTime())
      .slice(0, 8)
      .map((miss) => ({ at: formatVietnam(miss.at), medicineName: miss.medicineName })),
    prescriptions: groupPrescriptions(input.lines),
  };
}

export function renderComplianceHtml(report: ComplianceReport): string {
  const rate = report.rate === null ? 'Chưa đủ dữ liệu' : `${report.rate}%`;
  const medicineRows = report.medicines.length === 0
    ? '<tr><td colspan="4">Chưa có liều nào đã tới giờ trong 30 ngày.</td></tr>'
    : report.medicines.map((medicine) => `<tr><td>${escapeHtml(medicine.name)}</td><td>${medicine.onTime}</td><td>${medicine.missed}</td><td>${medicine.rate === null ? '—' : `${medicine.rate}%`}</td></tr>`).join('');
  const missRows = report.recentMisses.length === 0
    ? '<tr><td colspan="2">Không có lần quên trong 30 ngày.</td></tr>'
    : report.recentMisses.map((miss) => `<tr><td>${escapeHtml(miss.at)}</td><td>${escapeHtml(miss.medicineName)}</td></tr>`).join('');
  const prescriptionBlocks = report.prescriptions.length === 0
    ? '<p>Không có đơn đang điều trị.</p>'
    : report.prescriptions.map((prescription) => {
      const doctor = prescription.doctorName ? escapeHtml(prescription.doctorName) : 'Không ghi tên bác sĩ';
      const end = prescription.endDate ? displayDate(prescription.endDate) : 'chưa ấn định';
      const rows = prescription.medicines.map((medicine) => {
        const times = medicine.times.length > 0 ? medicine.times.join(', ') : 'Chưa có giờ nhắc';
        return `<tr><td>${escapeHtml(medicine.name)}</td><td>${escapeHtml(medicine.dosage)}</td><td>${escapeHtml(times)}</td></tr>`;
      }).join('');
      return `<h2>${escapeHtml(prescription.title)}</h2><p>${doctor}. Từ ${displayDate(prescription.startDate)} đến ${end}.</p><table><tr><th>Thuốc</th><th>Mỗi lần</th><th>Giờ nhắc</th></tr>${rows}</table>`;
    }).join('');

  return `<!DOCTYPE html>
<html lang="vi">
<head><meta charset="utf-8"><title>Báo cáo tuân thủ uống thuốc</title></head>
<body>
<h1>Báo cáo tuân thủ uống thuốc</h1>
<p>Bệnh nhân: ${escapeHtml(report.patientName)}. Kỳ báo cáo: ${displayDate(report.from)} – ${displayDate(report.to)} (30 ngày, giờ Việt Nam).</p>
<p>Lập lúc ${escapeHtml(formatVietnam(report.generatedAt))}.</p>
<h2>Tỷ lệ đúng giờ</h2>
<p>${rate}</p>
<p>Đúng giờ nghĩa là đã uống trong vòng 30 phút kể từ giờ nhắc. Liều chưa tới giờ không tính.</p>
<table>
<tr><th>Chỉ số</th><th>Số lần</th></tr>
<tr><td>Đúng giờ</td><td>${report.onTime}</td></tr>
<tr><td>Uống trễ</td><td>${report.late}</td></tr>
<tr><td>Quên</td><td>${report.missed}</td></tr>
<tr><td>Bỏ qua</td><td>${report.skipped}</td></tr>
<tr><td>Tổng liều đã tới giờ</td><td>${report.closed}</td></tr>
</table>
<h2>Theo từng thuốc</h2>
<table>
<tr><th>Thuốc</th><th>Đúng giờ</th><th>Quên</th><th>Tỷ lệ đúng giờ</th></tr>
${medicineRows}
</table>
<h2>Những lần quên gần nhất</h2>
<table>
<tr><th>Giờ nhắc</th><th>Thuốc</th></tr>
${missRows}
</table>
<h2>Đơn đang điều trị</h2>
${prescriptionBlocks}
<p>Báo cáo này để gửi bác sĩ khi thăm khám. Nó không thay cho hồ sơ bệnh án.</p>
</body>
</html>`;
}

export function parseReportHtml(html: string): ReportBlock[] {
  const body = html.match(/<body[^>]*>([\s\S]*)<\/body>/i)?.[1] ?? html;
  const blocks: ReportBlock[] = [];
  for (const match of body.matchAll(/<(h1|h2|p|table)\b[^>]*>([\s\S]*?)<\/\1>/gi)) {
    const tag = match[1].toLowerCase();
    if (tag === 'table') {
      const rows = [...match[2].matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)]
        .map((row) => [...row[1].matchAll(/<t[dh]\b[^>]*>([\s\S]*?)<\/t[dh]>/gi)].map((cell) => decodeHtml(cell[1])))
        .filter((row) => row.length > 0);
      blocks.push({ kind: 'table', rows });
      continue;
    }
    blocks.push({ kind: tag as 'h1' | 'h2' | 'p', text: decodeHtml(match[2]) });
  }
  return blocks;
}

export function renderCompliancePdf(html: string): Promise<Buffer> {
  const blocks = parseReportHtml(html);
  if (blocks.length === 0) {
    throw new Error('Compliance report HTML has no content');
  }
  const font = Buffer.from(COMPLIANCE_REPORT_FONT, 'base64');
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 48, compress: false });
    const chunks: Buffer[] = [];
    doc.on('data', (chunk: Buffer) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    doc.registerFont('Report', font);
    doc.font('Report');
    for (const block of blocks) {
      ensureRoom(doc, block.kind === 'table' ? 36 : 24);
      if (block.kind === 'h1') {
        doc.fontSize(18).fillColor('#1F3A5F').text(block.text, { paragraphGap: 6 });
      } else if (block.kind === 'h2') {
        doc.moveDown(0.4);
        doc.fontSize(13).fillColor('#1F6B4A').text(block.text, { paragraphGap: 4 });
      } else if (block.kind === 'p') {
        doc.fontSize(11).fillColor('#1C1C1C').text(block.text, { paragraphGap: 3 });
      } else if (block.kind === 'table') {
        drawTable(doc, block.rows);
      }
    }
    doc.end();
  });
}

function outcomeOf(dose: ComplianceDose) {
  if (dose.status === 'SKIPPED') {
    return 'skipped';
  }
  if (dose.status !== 'TAKEN') {
    return 'missed';
  }
  if (!dose.actualTakenAt) {
    return 'late';
  }
  const delta = Math.abs(dose.actualTakenAt.getTime() - dose.scheduledAt.getTime());
  return delta <= ON_TIME_MS ? 'onTime' : 'late';
}

function isStillOpen(dose: ComplianceDose, now: Date) {
  if (dose.status === 'TAKEN' || dose.status === 'MISSED' || dose.status === 'SKIPPED') {
    return false;
  }
  const anchor = dose.status === 'SNOOZED' && dose.snoozeUntil ? dose.snoozeUntil : dose.scheduledAt;
  return now.getTime() < anchor.getTime() + MISSED_AFTER_MS;
}

function rateOf(onTime: number, closed: number) {
  if (closed === 0) {
    return null;
  }
  return Math.round((onTime / closed) * 100);
}

function groupPrescriptions(lines: ComplianceMedicineLine[]) {
  const groups = new Map<string, ComplianceReport['prescriptions'][number] & { medicineIndex: Map<string, number> }>();
  for (const line of lines) {
    let group = groups.get(line.prescriptionId);
    if (!group) {
      group = {
        title: clean(line.title) || 'Đơn thuốc',
        doctorName: clean(line.doctorName ?? '') || null,
        startDate: line.startDate,
        endDate: line.endDate,
        medicines: [],
        medicineIndex: new Map(),
      };
      groups.set(line.prescriptionId, group);
    }
    const name = clean(line.medicineName) || 'Thuốc';
    const dosage = dosageText(line.dosage, line.unit);
    let index = group.medicineIndex.get(`${name}|${dosage}`);
    if (index === undefined) {
      index = group.medicines.length;
      group.medicines.push({ name, dosage, times: [] });
      group.medicineIndex.set(`${name}|${dosage}`, index);
    }
    const time = clock(line.reminderTime);
    const medicine = group.medicines[index];
    if (time && !medicine.times.includes(time)) {
      medicine.times.push(time);
      medicine.times.sort();
    }
  }
  return [...groups.values()].map(({ medicineIndex: _medicineIndex, ...group }) => group);
}

function dosageText(value: string, unit: string) {
  const amount = Number(value);
  const shown = Number.isFinite(amount) ? String(amount) : clean(value);
  const label = unit === 'GOI' ? 'gói' : unit === 'CHAI' ? 'chai' : 'viên';
  return `${shown || '—'} ${label}`;
}

function clock(value: string | null) {
  const match = value?.match(/^([01]\d|2[0-3]):([0-5]\d)/);
  return match ? `${match[1]}:${match[2]}` : '';
}

function displayDate(iso: string) {
  const match = iso.match(/^(\d{4})-(\d{2})-(\d{2})/);
  return match ? `${match[3]}/${match[2]}/${match[1]}` : iso;
}

function formatVietnam(value: Date) {
  return new Intl.DateTimeFormat('vi-VN', {
    timeZone: 'Asia/Ho_Chi_Minh',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(value);
}

function clean(value: string) {
  return value.replace(/[\u0000-\u001F]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 200);
}

function escapeHtml(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function decodeHtml(value: string) {
  return value
    .replace(/<[^>]+>/g, '')
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ')
    .trim();
}

function ensureRoom(doc: PDFKit.PDFDocument, needed: number) {
  if (doc.y + needed <= doc.page.height - doc.page.margins.bottom) {
    return;
  }
  doc.addPage();
}

function drawTable(doc: PDFKit.PDFDocument, rows: string[][]) {
  const startX = doc.page.margins.left;
  const width = doc.page.width - doc.page.margins.left - doc.page.margins.right;
  const columns = Math.max(1, ...rows.map((row) => row.length));
  const columnWidth = width / columns;
  doc.fontSize(10).fillColor('#1C1C1C');
  for (const row of rows) {
    ensureRoom(doc, 20);
    const y = doc.y;
    row.forEach((cell, index) => {
      doc.text(cell, startX + index * columnWidth + 2, y, {
        width: columnWidth - 6,
        height: 16,
        ellipsis: true,
      });
      doc.y = y;
    });
    doc.y = y + 18;
    doc.moveTo(startX, doc.y).lineTo(startX + width, doc.y).strokeColor('#D5DDE5').stroke();
  }
  doc.moveDown(0.3);
}
