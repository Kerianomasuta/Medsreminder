import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {
  DataSource,
  EntityManager,
  MoreThanOrEqual,
  Repository,
} from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { DoseStatus } from '../enums/dose-status.enum.js';
import { MedicationLog } from '../medication-logs/schema/medication-log.entity.js';
import { scheduledDoseInstants } from '../medication-logs/scheduled-doses.js';
import { Prescription } from '../prescriptions/schema/prescription.entity.js';
import { PrescriptionItem } from '../prescriptions/schema/prescription-item.entity.js';
import { ScheduleRule } from './schema/schedule-rule.entity.js';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const OBJECT_ID_PATTERN = /^[0-9a-f]{24}$/i;
const TIME_PATTERN = /^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$/;
const ALL_WEEK = [1, 2, 3, 4, 5, 6, 7];

const RULE_RELATIONS = {
  prescriptionItem: {
    prescription: true,
  },
} as const;

export type ScheduleActor = {
  userId?: string;
  role?: string;
};

export type CreateScheduleInput = {
  reminderTime?: string;
  daysOfWeek?: number[];
};

export type UpdateScheduleInput = {
  reminderTime?: string;
  daysOfWeek?: number[];
  isActive?: boolean;
};

@Injectable()
export class ScheduleRulesService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(ScheduleRule)
    private readonly rules: Repository<ScheduleRule>,
    @InjectRepository(PrescriptionItem)
    private readonly items: Repository<PrescriptionItem>,
  ) {}

  async list(patientId?: string, isActive?: boolean, actor?: ScheduleActor) {
    const id =
      this.patientOwnerId(actor) ??
      this.requireObjectId(patientId, 'patientId');
    if (isActive !== undefined && typeof isActive !== 'boolean') {
      throw ErrorHandling.BadRequest('isActive must be true or false');
    }

    const rows = await this.rules.find({
      where: {
        patientId: id,
        ...(isActive === undefined ? {} : { isActive }),
      },
      relations: RULE_RELATIONS,
      order: { reminderTime: 'ASC' },
    });

    return rows.map((rule) => this.toResponse(rule));
  }

  async getById(id: string, actor?: ScheduleActor) {
    const rule = await this.findRule(id);
    this.assertPatientOwns(rule.prescriptionItem.prescription.patientId, actor);
    return this.toResponse(rule);
  }

  async create(
    prescriptionItemId: string | undefined,
    payload: CreateScheduleInput,
    actor?: ScheduleActor,
  ) {
    const item = await this.findItem(prescriptionItemId);
    this.assertPatientOwns(item.prescription.patientId, actor);
    const saved = await this.dataSource.transaction(async (manager) => {
      const rule = await manager.save(
        ScheduleRule,
        manager.create(ScheduleRule, {
          prescriptionItemId: item.id,
          patientId: item.prescription.patientId,
          reminderTime: this.requireTime(payload.reminderTime),
          daysOfWeek: this.normalizeDays(payload.daysOfWeek),
          isActive: true,
        }),
      );
      await this.saveScheduledLogs(manager, rule, item.prescription);
      return rule;
    });
    saved.prescriptionItem = item;
    return this.toResponse(saved);
  }

  async update(
    id: string,
    payload: UpdateScheduleInput,
    actor?: ScheduleActor,
  ) {
    const hasChange = ['reminderTime', 'daysOfWeek', 'isActive'].some(
      (field) => payload[field as keyof UpdateScheduleInput] !== undefined,
    );
    if (!hasChange) {
      throw ErrorHandling.BadRequest('Provide at least one field to update');
    }

    const rule = await this.findRule(id);
    this.assertPatientOwns(rule.prescriptionItem.prescription.patientId, actor);
    if (payload.reminderTime !== undefined) {
      rule.reminderTime = this.requireTime(payload.reminderTime);
    }
    if (payload.daysOfWeek !== undefined) {
      rule.daysOfWeek = this.normalizeDays(payload.daysOfWeek);
    }
    if (payload.isActive !== undefined) {
      rule.isActive = this.requireBoolean(payload.isActive, 'isActive');
    }

    const saved = await this.dataSource.transaction(async (manager) => {
      const updated = await manager.save(ScheduleRule, rule);
      updated.prescriptionItem = rule.prescriptionItem;
      await this.rescheduleOpenLogs(
        manager,
        updated,
        rule.prescriptionItem.prescription,
      );
      return updated;
    });
    saved.prescriptionItem = rule.prescriptionItem;
    return this.toResponse(saved);
  }

  /**
   * Medication logs are execution records, but future SCHEDULED rows must follow
   * the current rule because they are also the source used by mobile alarms.
   * Final rows are preserved as patient history. Snoozed rows are preserved
   * while active, but removed when the rule is disabled so no alarm can fire.
   */
  private async rescheduleOpenLogs(
    manager: EntityManager,
    rule: ScheduleRule,
    prescription: Prescription,
    now = new Date(),
  ) {
    const todayStart = this.startOfVietnamDay(now);
    const current = await manager.find(MedicationLog, {
      where: {
        scheduleRuleId: rule.id,
        scheduledAt: MoreThanOrEqual(todayStart),
      },
    });
    const disabled = !rule.isActive || !prescription.isActive;
    const replaceable = current.filter(
      (log) =>
        log.status === DoseStatus.SCHEDULED ||
        (disabled && log.status === DoseStatus.SNOOZED),
    );
    if (replaceable.length > 0) {
      await manager.remove(MedicationLog, replaceable);
    }

    if (disabled) {
      return;
    }

    const protectedDates = new Set(
      current
        .filter((log) => !replaceable.includes(log))
        .map((log) => this.vietnamDate(log.scheduledAt)),
    );
    const instants = scheduledDoseInstants({
      startDate: prescription.startDate,
      endDate: prescription.endDate,
      reminderTime: rule.reminderTime,
      daysOfWeek: rule.daysOfWeek,
    }).filter(
      (scheduledAt) =>
        scheduledAt.getTime() > now.getTime() &&
        !protectedDates.has(this.vietnamDate(scheduledAt)),
    );

    for (const scheduledAt of instants) {
      await manager.save(
        MedicationLog,
        manager.create(MedicationLog, {
          scheduleRuleId: rule.id,
          patientId: rule.patientId,
          scheduledAt,
          status: DoseStatus.SCHEDULED,
          escalationLevel: 0,
        }),
      );
    }
  }

  private async saveScheduledLogs(
    manager: EntityManager,
    rule: Pick<
      ScheduleRule,
      'id' | 'patientId' | 'reminderTime' | 'daysOfWeek'
    >,
    prescription: Pick<Prescription, 'startDate' | 'endDate'>,
  ) {
    const instants = scheduledDoseInstants({
      startDate: prescription.startDate,
      endDate: prescription.endDate,
      reminderTime: rule.reminderTime,
      daysOfWeek: rule.daysOfWeek,
    });

    for (const scheduledAt of instants) {
      await manager.save(
        MedicationLog,
        manager.create(MedicationLog, {
          scheduleRuleId: rule.id,
          patientId: rule.patientId,
          scheduledAt,
          status: DoseStatus.SCHEDULED,
          escalationLevel: 0,
        }),
      );
    }
  }

  private async findItem(id: string | undefined) {
    const itemId = this.requireUuid(id, 'prescriptionItemId');
    const item = await this.items.findOne({
      where: { id: itemId },
      relations: { prescription: true },
    });
    if (!item?.prescription) {
      throw ErrorHandling.NotFound('Prescription item not found');
    }
    return item;
  }

  private async findRule(id: string) {
    this.requireUuid(id, 'schedule id');
    const rule = await this.rules.findOne({
      where: { id },
      relations: RULE_RELATIONS,
    });
    if (!rule?.prescriptionItem?.prescription) {
      throw ErrorHandling.NotFound('Schedule not found');
    }
    return rule;
  }

  private patientOwnerId(actor?: ScheduleActor) {
    if (actor?.role !== 'PATIENT') {
      return undefined;
    }
    return this.requireObjectId(actor.userId, 'userId');
  }

  private assertPatientOwns(
    patientId: string | undefined,
    actor?: ScheduleActor,
  ) {
    const userId = this.patientOwnerId(actor);
    if (userId !== undefined && patientId !== userId) {
      throw ErrorHandling.Forbidden(
        'A patient can only access their own prescription',
      );
    }
  }

  private requireUuid(value: string | undefined, label: string) {
    if (!value || !UUID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be a UUID`);
    }
    return value;
  }

  private requireObjectId(value: string | undefined, label: string) {
    if (!value || !OBJECT_ID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be an ObjectId`);
    }
    return value;
  }

  private requireTime(value: string | undefined) {
    const match = TIME_PATTERN.exec(value?.trim() ?? '');
    if (!match) {
      throw ErrorHandling.BadRequest('reminderTime must be HH:mm');
    }
    return `${match[1]}:${match[2]}:${match[3] ?? '00'}`;
  }

  private normalizeDays(days: number[] | undefined) {
    if (days == null) {
      return [...ALL_WEEK];
    }
    if (days.length === 0) {
      throw ErrorHandling.BadRequest(
        'daysOfWeek must contain at least one day',
      );
    }

    const unique = [...new Set(days)];
    if (unique.some((day) => !Number.isInteger(day) || day < 1 || day > 7)) {
      throw ErrorHandling.BadRequest('daysOfWeek must be integers from 1 to 7');
    }
    return unique.sort((left, right) => left - right);
  }

  private requireBoolean(value: boolean, label: string) {
    if (typeof value !== 'boolean') {
      throw ErrorHandling.BadRequest(`${label} must be true or false`);
    }
    return value;
  }

  private startOfVietnamDay(value: Date) {
    return new Date(`${this.vietnamDate(value)}T00:00:00+07:00`);
  }

  private vietnamDate(value: Date | string) {
    const date = value instanceof Date ? value : new Date(value);
    return new Date(date.getTime() + 7 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 10);
  }

  private toResponse(rule: ScheduleRule) {
    const item = rule.prescriptionItem;
    return {
      id: rule.id,
      prescriptionItemId: rule.prescriptionItemId,
      patientId: rule.patientId,
      reminderTime: rule.reminderTime,
      daysOfWeek: rule.daysOfWeek,
      isActive: rule.isActive,
      dosagePerTime: Number(item.dosagePerTime),
      instructions: item.instructions,
      medicine: {
        name: item.name,
        genericName: item.genericName,
        unit: item.unit,
        imageUrl: item.imageUrl,
      },
      prescription: {
        id: item.prescription.id,
        title: item.prescription.title,
        startDate: item.prescription.startDate,
        endDate: item.prescription.endDate,
        isActive: item.prescription.isActive,
      },
    };
  }
}
