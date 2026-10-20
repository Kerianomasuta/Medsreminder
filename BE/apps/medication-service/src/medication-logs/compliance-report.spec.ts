import { describe, expect, it } from 'vitest';
import {
  buildComplianceReport,
  parseReportHtml,
  renderComplianceHtml,
  renderCompliancePdf,
  type ComplianceDose,
} from './compliance-report.js';

const now = new Date('2026-10-15T03:00:00.000Z');

function dose(overrides: Partial<ComplianceDose> & Pick<ComplianceDose, 'status' | 'scheduledAt'>): ComplianceDose {
  return {
    medicineName: 'Paracetamol',
    actualTakenAt: null,
    snoozeUntil: null,
    ...overrides,
  };
}

describe('buildComplianceReport', () => {
  it('reports 85 percent when 17 of 20 due doses were taken within 30 minutes', () => {
    const doses: ComplianceDose[] = [];
    for (let index = 0; index < 17; index += 1) {
      const scheduledAt = new Date('2026-10-01T01:00:00.000Z');
      scheduledAt.setUTCDate(scheduledAt.getUTCDate() + index);
      doses.push(dose({
        status: 'TAKEN',
        scheduledAt,
        actualTakenAt: new Date(scheduledAt.getTime() + 5 * 60 * 1000),
      }));
    }
    for (let index = 0; index < 3; index += 1) {
      doses.push(dose({
        medicineName: 'Amlodipine',
        status: 'MISSED',
        scheduledAt: new Date('2026-10-10T05:00:00.000Z'),
      }));
    }
    doses.push(dose({
      status: 'SCHEDULED',
      scheduledAt: new Date('2026-10-15T10:00:00.000Z'),
    }));

    const report = buildComplianceReport({
      patientName: 'Nguyễn Văn A',
      from: '2026-09-16',
      to: '2026-10-15',
      now,
      doses,
      lines: [{
        prescriptionId: 'rx-1',
        title: 'Huyết áp',
        doctorName: 'BS Lan',
        startDate: '2026-10-01',
        endDate: null,
        medicineName: 'Amlodipine',
        dosage: '1.00',
        unit: 'VIEN',
        reminderTime: '08:00:00',
      }],
    });

    expect(report.rate).toBe(85);
    expect(report.missed).toBe(3);
    expect(report.closed).toBe(20);
    expect(report.prescriptions[0]?.medicines[0]).toEqual({
      name: 'Amlodipine',
      dosage: '1 viên',
      times: ['08:00'],
    });
  });

  it('counts an overdue scheduled dose as missed and a dose taken after 30 minutes as late', () => {
    const report = buildComplianceReport({
      patientName: '  ',
      from: '2026-09-16',
      to: '2026-10-15',
      now,
      doses: [
        dose({
          status: 'SCHEDULED',
          scheduledAt: new Date('2026-10-15T01:00:00.000Z'),
        }),
        dose({
          status: 'TAKEN',
          scheduledAt: new Date('2026-10-14T01:00:00.000Z'),
          actualTakenAt: new Date('2026-10-14T02:30:00.000Z'),
        }),
      ],
      lines: [],
    });

    expect(report.patientName).toBe('Bệnh nhân');
    expect(report.missed).toBe(1);
    expect(report.late).toBe(1);
    expect(report.rate).toBe(0);
  });
});

describe('compliance report document', () => {
  it('fills the HTML template and renders a PDF buffer', async () => {
    const report = buildComplianceReport({
      patientName: 'Nguyễn <Lan>',
      from: '2026-09-16',
      to: '2026-10-15',
      now,
      doses: [dose({
        status: 'TAKEN',
        scheduledAt: new Date('2026-10-14T01:00:00.000Z'),
        actualTakenAt: new Date('2026-10-14T01:04:00.000Z'),
      })],
      lines: [],
    });
    const html = renderComplianceHtml(report);
    const blocks = parseReportHtml(html);

    expect(html).toContain('100%');
    expect(html).toContain('Nguyễn &lt;Lan&gt;');
    expect(blocks.some((block) => block.kind === 'h1' && block.text.includes('tuân thủ'))).toBe(true);

    const pdf = await renderCompliancePdf(html);
    expect(pdf.subarray(0, 5).toString('ascii')).toBe('%PDF-');
    expect(pdf.length).toBeGreaterThan(1000);
  });
});
