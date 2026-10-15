import { describe, expect, it } from 'vitest';
import { parsePrescriptionDraft } from './prescription-draft.js';

describe('parsePrescriptionDraft', () => {
  it('reads a fenced JSON draft and maps Vietnamese dose words', () => {
    const draft = parsePrescriptionDraft(`
      Here is the form:
      \`\`\`json
      {
        "title": "Đơn bác sĩ Lan",
        "doctorName": "BS Lan",
        "prescriptionCode": "ĐT-01",
        "startDate": "2026-10-01",
        "endDate": "2026-10-14",
        "items": [
          {
            "name": "Paracetamol 500mg",
            "unit": "viên",
            "dosagePerTime": "1 viên",
            "currentStock": 20,
            "instructions": "Sau ăn",
            "schedules": [
              { "reminderTime": "sáng", "daysOfWeek": [1, 2, 3, 4, 5, 6, 7] },
              { "reminderTime": "20:30", "daysOfWeek": [] }
            ]
          }
        ]
      }
      \`\`\`
    `);

    expect(draft).toEqual({
      title: 'Đơn bác sĩ Lan',
      doctorName: 'BS Lan',
      prescriptionCode: 'ĐT-01',
      startDate: '2026-10-01',
      endDate: '2026-10-14',
      items: [
        {
          name: 'Paracetamol 500mg',
          unit: 'VIEN',
          dosagePerTime: 1,
          currentStock: 20,
          instructions: 'Sau ăn',
          schedules: [
            { reminderTime: '08:00', daysOfWeek: [1, 2, 3, 4, 5, 6, 7] },
            { reminderTime: '20:30', daysOfWeek: [1, 2, 3, 4, 5, 6, 7] },
          ],
        },
      ],
    });
  });

  it('drops a calendar date the model invented', () => {
    const draft = parsePrescriptionDraft(`{
      "title": "Đơn",
      "startDate": "2026-02-31",
      "endDate": "not-a-date",
      "items": [{ "name": "Amlodipine", "dosagePerTime": 1, "schedules": [{ "reminderTime": "08:00" }] }]
    }`);

    expect(draft.startDate).toBeNull();
    expect(draft.endDate).toBeNull();
    expect(draft.items[0]?.schedules[0]?.reminderTime).toBe('08:00');
  });

  it('rejects a reply that has no medicine line', () => {
    expect(() => parsePrescriptionDraft('{"title":"Trống","items":[]}')).toThrow(
      'No medicine line could be read from the prescription photo',
    );
  });
});
