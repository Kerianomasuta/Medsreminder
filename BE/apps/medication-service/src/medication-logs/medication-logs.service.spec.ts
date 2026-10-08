import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DoseStatus } from '../enums/dose-status.enum.js';
import { ScheduleRule } from '../schedule-rules/schema/schedule-rule.entity.js';
import { MedicationLogsService } from './medication-logs.service.js';
import { MedicationLog } from './schema/medication-log.entity.js';

const patientId = '507f1f77bcf86cd799439011';
const otherPatientId = '507f1f77bcf86cd799439099';
const logId = '66666666-6666-4666-8666-666666666666';
const ruleId = '77777777-7777-4777-8777-777777777777';
const scheduledAt = new Date('2026-10-08T01:00:00.000Z');

function dose(overrides: Record<string, unknown> = {}) {
  return {
    id: logId,
    scheduleRuleId: ruleId,
    patientId,
    scheduledAt,
    actualTakenAt: null,
    status: DoseStatus.SCHEDULED,
    snoozeUntil: null,
    escalationLevel: 0,
    skipReason: null,
    scheduleRule: {
      prescriptionItem: {
        name: 'Paracetamol',
        genericName: null,
        unit: 'VIEN',
        imageUrl: null,
        dosagePerTime: '2.00',
        instructions: 'Sau ăn',
      },
    },
    ...overrides,
  };
}

describe('MedicationLogsService', () => {
  const logs = new Map<string, ReturnType<typeof dose>>();
  const manager = {
    findOne: vi.fn(async (entity: { name: string }, options: { where: { id: string } }) => {
      if (entity === MedicationLog) {
        return logs.get(options.where.id) ?? null;
      }
      if (entity === ScheduleRule) {
        return logs.get(logId)?.scheduleRule ?? null;
      }
      return null;
    }),
    save: vi.fn(async (_entity: unknown, value: ReturnType<typeof dose>) => value),
  };
  const repository = { find: vi.fn() };
  const dataSource = {
    transaction: vi.fn(async (work: (current: typeof manager) => Promise<unknown>) => work(manager)),
  };
  let service: MedicationLogsService;

  beforeEach(() => {
    logs.clear();
    manager.findOne.mockClear();
    manager.save.mockClear();
    repository.find.mockReset();
    service = new MedicationLogsService(dataSource as never, repository as never);
  });

  it('records the device time when the patient takes a scheduled dose', async () => {
    logs.set(logId, dose());

    const taken = await service.take(logId, {
      userId: patientId,
      actedAt: '2026-10-08T01:04:00.000Z',
    });

    expect(taken).toMatchObject({
      status: DoseStatus.TAKEN,
      actualTakenAt: new Date('2026-10-08T01:04:00.000Z'),
      snoozeUntil: null,
      escalationLevel: 0,
      dosagePerTime: 2,
      medicine: { name: 'Paracetamol', unit: 'VIEN' },
    });
  });

  it('refuses to change a dose that is already taken', async () => {
    logs.set(logId, dose({ status: DoseStatus.TAKEN }));

    await expect(service.snooze(logId, { userId: patientId, minutes: 5 })).rejects.toMatchObject({
      message: 'This dose can no longer be changed',
    });
  });

  it('snoozes an open dose for ten minutes from the button time', async () => {
    logs.set(logId, dose());

    const snoozed = await service.snooze(logId, {
      userId: patientId,
      minutes: 10,
      actedAt: '2026-10-08T01:02:00.000Z',
    });

    expect(snoozed.status).toBe(DoseStatus.SNOOZED);
    expect(snoozed.snoozeUntil).toEqual(new Date('2026-10-08T01:12:00.000Z'));
    expect(snoozed.escalationLevel).toBe(0);
  });

  it('rejects a snooze that is not 5 or 10 minutes', async () => {
    logs.set(logId, dose());

    await expect(service.snooze(logId, { userId: patientId, minutes: 15 })).rejects.toMatchObject({
      message: 'minutes must be 5 or 10',
    });
  });

  it('marks a deliberate skip and raises escalation', async () => {
    logs.set(logId, dose({ status: DoseStatus.SNOOZED, snoozeUntil: new Date('2026-10-08T01:10:00.000Z') }));

    const skipped = await service.skip(logId, { userId: patientId, skipReason: ' Buồn nôn ' });

    expect(skipped).toMatchObject({
      status: DoseStatus.SKIPPED,
      skipReason: 'Buồn nôn',
      snoozeUntil: null,
      escalationLevel: 1,
    });
  });

  it('rejects a miss before both 10-minute alarms have finished', async () => {
    logs.set(logId, dose());

    await expect(service.miss(logId, {
      userId: patientId,
      actedAt: '2026-10-08T01:19:00.000Z',
    })).rejects.toMatchObject({
      message: 'A dose can be marked missed only 20 minutes after the current reminder',
    });
  });

  it('marks a snoozed dose missed 20 minutes after the snooze', async () => {
    logs.set(logId, dose({
      status: DoseStatus.SNOOZED,
      snoozeUntil: new Date('2026-10-08T01:10:00.000Z'),
    }));

    const missed = await service.miss(logId, {
      userId: patientId,
      actedAt: '2026-10-08T01:30:00.000Z',
    });

    expect(missed).toMatchObject({
      status: DoseStatus.MISSED,
      snoozeUntil: null,
      escalationLevel: 1,
    });
  });

  it('refuses a patient who does not own the dose', async () => {
    logs.set(logId, dose());

    await expect(service.take(logId, { userId: otherPatientId })).rejects.toMatchObject({
      message: 'A patient can only record their own dose',
    });
  });

  it('accepts the same patient id when only the letter case differs', async () => {
    logs.set(logId, dose());

    const taken = await service.take(logId, {
      userId: patientId.toUpperCase(),
      actedAt: '2026-10-08T01:04:00.000Z',
    });

    expect(taken.status).toBe(DoseStatus.TAKEN);
  });

  it('treats a null button time as the current server time', async () => {
    logs.set(logId, dose());

    const taken = await service.take(logId, { userId: patientId, actedAt: null });

    expect(taken.actualTakenAt).toBeInstanceOf(Date);
    expect((taken.actualTakenAt as Date).getTime()).toBeGreaterThan(Date.UTC(2020, 0, 1));
  });

  it('rejects a button time that has no timezone', async () => {
    logs.set(logId, dose());

    await expect(service.take(logId, {
      userId: patientId,
      actedAt: '2026-10-08T08:04:00',
    })).rejects.toMatchObject({
      message: 'actedAt must be an ISO-8601 time with a timezone',
    });
  });

  it('marks a dose missed at exactly 20 minutes', async () => {
    logs.set(logId, dose());

    const missed = await service.miss(logId, {
      userId: patientId,
      actedAt: '2026-10-08T01:20:00.000Z',
    });

    expect(missed.status).toBe(DoseStatus.MISSED);
  });

  it('uses a snooze time stored as text when deciding the missed deadline', async () => {
    logs.set(logId, dose({
      status: DoseStatus.SNOOZED,
      snoozeUntil: '2026-10-08T01:10:00.000Z',
    }));

    await expect(service.miss(logId, {
      userId: patientId,
      actedAt: '2026-10-08T01:29:00.000Z',
    })).rejects.toMatchObject({
      message: 'A dose can be marked missed only 20 minutes after the current reminder',
    });
  });
});
