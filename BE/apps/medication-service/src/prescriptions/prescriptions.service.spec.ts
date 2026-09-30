import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Medicine } from '../medicines/schema/medicine.entity.js';
import { ScheduleRule } from '../schedule-rules/schema/schedule-rule.entity.js';
import { PrescriptionsService } from './prescriptions.service.js';

const patientId = '11111111-1111-4111-8111-111111111111';
const caregiverId = '22222222-2222-4222-8222-222222222222';
const medicineId = '33333333-3333-4333-8333-333333333333';

function createManager(medicine: { id: string } | null) {
  const saves: Array<{ entity: string; value: Record<string, unknown> }> = [];
  return {
    saves,
    findOne: vi.fn(async (entity: { name: string }) => (entity === Medicine ? medicine : null)),
    create: vi.fn((_entity: unknown, value: Record<string, unknown>) => ({ ...value })),
    save: vi.fn(async (entity: { name: string }, value: Record<string, unknown>) => {
      const saved = {
        id: `${entity.name}-${saves.length + 1}`,
        createdAt: new Date('2026-10-01T00:00:00.000Z'),
        updatedAt: new Date('2026-10-01T00:00:00.000Z'),
        ...value,
      };
      saves.push({ entity: entity.name, value: saved });
      return saved;
    }),
  };
}

describe('PrescriptionsService', () => {
  let manager: ReturnType<typeof createManager>;
  let service: PrescriptionsService;

  function buildService(medicine: { id: string } | null) {
    manager = createManager(medicine);
    const dataSource = {
      transaction: vi.fn(async (work: (current: typeof manager) => Promise<unknown>) => work(manager)),
    };
    service = new PrescriptionsService(dataSource as never, {} as never, {} as never, {} as never);
  }

  beforeEach(() => {
    buildService({ id: medicineId });
  });

  it('rejects a medicine that is not in the catalog', async () => {
    buildService(null);

    await expect(service.create(validPrescription())).rejects.toMatchObject({
      message: 'Medicine not found',
    });
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('saves two schedules when one medicine is taken twice a day', async () => {
    const created = await service.create(validPrescription());

    const scheduleSaves = manager.saves.filter((entry) => entry.entity === ScheduleRule.name);
    expect(scheduleSaves).toHaveLength(2);
    expect(scheduleSaves.map((entry) => entry.value.reminderTime)).toEqual(['08:00:00', '20:00:00']);
    expect(scheduleSaves.every((entry) => entry.value.patientId === patientId)).toBe(true);
    expect(created.items).toHaveLength(1);
    expect(created.items[0].schedules).toHaveLength(2);
  });
});

function validPrescription() {
  return {
    patientId,
    createdByCgId: caregiverId,
    title: 'Đơn tháng 10',
    startDate: '2026-10-01',
    endDate: '2026-10-31',
    items: [
      {
        medicineId,
        dosagePerTime: 2,
        currentStock: 30,
        schedules: [
          { reminderTime: '08:00' },
          { reminderTime: '20:00', daysOfWeek: [1, 2, 3, 4, 5, 6, 7] },
        ],
      },
    ],
  };
}
