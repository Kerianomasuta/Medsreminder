import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ScheduleRulesService } from './schedule-rules.service.js';

const patientId = '11111111-1111-4111-8111-111111111111';
const itemId = '44444444-4444-4444-8444-444444444444';

function createItem() {
  return {
    id: itemId,
    dosagePerTime: '2.00',
    instructions: 'Sau ăn',
    prescription: {
      id: '55555555-5555-4555-8555-555555555555',
      patientId,
      title: 'Đơn tháng 10',
      startDate: '2026-10-01',
      endDate: '2026-10-31',
      isActive: true,
    },
    medicine: {
      id: '33333333-3333-4333-8333-333333333333',
      name: 'Paracetamol',
      unit: 'VIEN',
      imageUrl: 'https://example.com/paracetamol.png',
    },
  };
}

describe('ScheduleRulesService', () => {
  const rules = {
    create: vi.fn((value) => value),
    save: vi.fn(async (value) => ({ id: 'rule-1', ...value })),
    find: vi.fn(),
    findOne: vi.fn(),
  };
  const items = {
    findOne: vi.fn(),
  };
  let service: ScheduleRulesService;

  beforeEach(() => {
    rules.create.mockClear();
    rules.save.mockClear();
    rules.find.mockReset();
    items.findOne.mockReset();
    service = new ScheduleRulesService(rules as never, items as never);
  });

  it('rejects a schedule for a medicine line that does not exist', async () => {
    items.findOne.mockResolvedValue(null);

    await expect(service.create(itemId, { reminderTime: '08:00' })).rejects.toMatchObject({
      message: 'Prescription item not found',
    });
    expect(rules.save).not.toHaveBeenCalled();
  });

  it('copies the patient from the prescription when adding a dose time', async () => {
    items.findOne.mockResolvedValue(createItem());

    const created = await service.create(itemId, { reminderTime: '20:00' });

    expect(rules.create).toHaveBeenCalledWith({
      prescriptionItemId: itemId,
      patientId,
      reminderTime: '20:00:00',
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      isActive: true,
    });
    expect(created.patientId).toBe(patientId);
    expect(created.medicine.name).toBe('Paracetamol');
    expect(created.medicine.imageUrl).toBe('https://example.com/paracetamol.png');
    expect(created.dosagePerTime).toBe(2);
  });
});
