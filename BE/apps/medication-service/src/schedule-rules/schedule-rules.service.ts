import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { DoseStatus } from '../enums/dose-status.enum.js';
import { MedicationLog } from '../medication-logs/schema/medication-log.entity.js';
import { scheduledDoseInstants } from '../medication-logs/scheduled-doses.js';
import { Prescription } from '../prescriptions/schema/prescription.entity.js';
import { PrescriptionItem } from '../prescriptions/schema/prescription-item.entity.js';
import { ScheduleRule } from './schema/schedule-rule.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const TIME_PATTERN = /^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$/;
const ALL_WEEK = [1, 2, 3, 4, 5, 6, 7];

const RULE_RELATIONS = {
  prescriptionItem: {
    medicine: true,
    prescription: true,
  },
} as const;

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

  async list(patientId?: string, isActive?: boolean) {
    const id = this.requireUuid(patientId, 'patientId');
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

  async getById(id: string) {
    return this.toResponse(await this.findRule(id));
  }

  async create(prescriptionItemId: string | undefined, payload: CreateScheduleInput) {
    const item = await this.findItem(prescriptionItemId);
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

  async update(id: string, payload: UpdateScheduleInput) {
    const hasChange = ['reminderTime', 'daysOfWeek', 'isActive'].some(
      (field) => payload[field as keyof UpdateScheduleInput] !== undefined,
    );
    if (!hasChange) {
      throw ErrorHandling.BadRequest('Provide at least one field to update');
    }

    const rule = await this.findRule(id);
    if (payload.reminderTime !== undefined) {
      rule.reminderTime = this.requireTime(payload.reminderTime);
    }
    if (payload.daysOfWeek !== undefined) {
      rule.daysOfWeek = this.normalizeDays(payload.daysOfWeek);
    }
    if (payload.isActive !== undefined) {
      rule.isActive = this.requireBoolean(payload.isActive, 'isActive');
    }

    const saved = await this.rules.save(rule);
    saved.prescriptionItem = rule.prescriptionItem;
    return this.toResponse(saved);
  }

  private async saveScheduledLogs(
    manager: EntityManager,
    rule: Pick<ScheduleRule, 'id' | 'patientId' | 'reminderTime' | 'daysOfWeek'>,
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
      relations: { medicine: true, prescription: true },
    });
    if (!item?.prescription || !item.medicine) {
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
    if (!rule?.prescriptionItem?.prescription || !rule.prescriptionItem.medicine) {
      throw ErrorHandling.NotFound('Schedule not found');
    }
    return rule;
  }

  private requireUuid(value: string | undefined, label: string) {
    if (!value || !UUID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be a UUID`);
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
      throw ErrorHandling.BadRequest('daysOfWeek must contain at least one day');
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
        id: item.medicine.id,
        name: item.medicine.name,
        unit: item.medicine.unit,
        imageUrl: item.medicine.imageUrl,
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
