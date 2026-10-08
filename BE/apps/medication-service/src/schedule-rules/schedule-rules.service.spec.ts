import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DoseStatus } from '../enums/dose-status.enum.js';
import { MedicationLog } from '../medication-logs/schema/medication-log.entity.js';
import { ScheduleRule } from './schema/schedule-rule.entity.js';
import { ScheduleRulesService } from './schedule-rules.service.js';

const patientId = '507f1f77bcf86cd799439011';
const itemId = '44444444-4444-4444-8444-444444444444';

function createItem() {
  return {
    id: itemId,
    name: 'Paracetamol',
    genericName: 'Acetaminophen',
    unit: 'VIEN',
    imageUrl: 'https://example.com/paracetamol.png',
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
  };
}

describe('ScheduleRulesService', () => {
  const rules = {
    find: vi.fn(),
    findOne: vi.fn(),
  };
  const items = {
    findOne: vi.fn(),
  };
  const manager = {
    creates: [] as Array<{ entity: string; value: Record<string, unknown> }>,
    create: vi.fn((entity: { name: string }, value: Record<string, unknown>) => {
      manager.creates.push({ entity: entity.name, value });
      return value;
    }),
    save: vi.fn(async (entity: { name: string }, value: Record<string, unknown>) => {
      if (entity === ScheduleRule) {
        return { id: 'rule-1', ...value };
      }
      return value;
    }),
  };
  const dataSource = {
    transaction: vi.fn(async (work: (current: typeof manager) => Promise<unknown>) => work(manager)),
  };
  let service: ScheduleRulesService;

  beforeEach(() => {
    rules.find.mockReset();
    rules.findOne.mockReset();
    items.findOne.mockReset();
    manager.creates = [];
    manager.create.mockClear();
    manager.save.mockClear();
    service = new ScheduleRulesService(dataSource as never, rules as never, items as never);
  });

  it('rejects a schedule for a medicine line that does not exist', async () => {
    items.findOne.mockResolvedValue(null);

    await expect(service.create(itemId, { reminderTime: '08:00' })).rejects.toMatchObject({
      message: 'Prescription item not found',
    });
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('refuses a patient who does not own the prescription line', async () => {
    items.findOne.mockResolvedValue(createItem());

    await expect(service.create(itemId, { reminderTime: '08:00' }, {
      userId: '507f1f77bcf86cd799439099',
      role: 'PATIENT',
    })).rejects.toMatchObject({
      message: 'A patient can only access their own prescription',
    });
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('copies the patient from the prescription when adding a dose time', async () => {
    items.findOne.mockResolvedValue(createItem());

    const created = await service.create(itemId, { reminderTime: '20:00' });

    expect(manager.create).toHaveBeenCalledWith(ScheduleRule, {
      prescriptionItemId: itemId,
      patientId,
      reminderTime: '20:00:00',
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      isActive: true,
    });
    const logs = manager.creates.filter((entry) => entry.entity === MedicationLog.name);
    expect(logs).toHaveLength(31);
    expect(logs.every((entry) => entry.value.status === DoseStatus.SCHEDULED)).toBe(true);
    expect(created.patientId).toBe(patientId);
    expect(created.medicine.name).toBe('Paracetamol');
    expect(created.medicine.imageUrl).toBe('https://example.com/paracetamol.png');
    expect(created.dosagePerTime).toBe(2);
  });
});
