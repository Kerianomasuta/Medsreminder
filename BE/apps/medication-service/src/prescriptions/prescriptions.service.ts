import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { DoseStatus } from '../enums/dose-status.enum.js';
import { MedicineUnit } from '../enums/medicine-unit.enum.js';
import { MedicationLog } from '../medication-logs/schema/medication-log.entity.js';
import { scheduledDoseInstants } from '../medication-logs/scheduled-doses.js';
import { ScheduleRule } from '../schedule-rules/schema/schedule-rule.entity.js';
import { PrescriptionItem } from './schema/prescription-item.entity.js';
import { Prescription } from './schema/prescription.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const TIME_PATTERN = /^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$/;
const ALL_WEEK = [1, 2, 3, 4, 5, 6, 7];

export type ScheduleInput = {
  reminderTime?: string;
  daysOfWeek?: number[];
};

export type PrescriptionItemInput = {
  name?: string;
  genericName?: string | null;
  unit?: string;
  imageUrl?: string | null;
  dosagePerTime?: number;
  currentStock?: number;
  reorderThreshold?: number;
  instructions?: string | null;
  schedules?: ScheduleInput[];
};

export type CreatePrescriptionInput = {
  patientId?: string;
  createdByCgId?: string;
  title?: string;
  doctorName?: string | null;
  prescriptionCode?: string | null;
  imagePrescriptionUrl?: string | null;
  startDate?: string;
  endDate?: string | null;
  items?: PrescriptionItemInput[];
};

export type UpdatePrescriptionInput = {
  title?: string;
  doctorName?: string | null;
  prescriptionCode?: string | null;
  imagePrescriptionUrl?: string | null;
  startDate?: string;
  endDate?: string | null;
  isActive?: boolean;
};

export type UpdatePrescriptionItemInput = {
  name?: string;
  genericName?: string | null;
  unit?: string;
  imageUrl?: string | null;
  dosagePerTime?: number;
  currentStock?: number;
  reorderThreshold?: number;
  instructions?: string | null;
};

type PreparedItem = {
  name: string;
  genericName: string | null;
  unit: MedicineUnit;
  imageUrl: string | null;
  dosagePerTime: string;
  currentStock: number;
  reorderThreshold: number;
  instructions: string | null;
  schedules: Array<{ reminderTime: string; daysOfWeek: number[] }>;
};

@Injectable()
export class PrescriptionsService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(Prescription)
    private readonly prescriptions: Repository<Prescription>,
    @InjectRepository(PrescriptionItem)
    private readonly prescriptionItems: Repository<PrescriptionItem>,
  ) {}

  async create(payload: CreatePrescriptionInput) {
    const patientId = this.requireUuid(payload.patientId, 'patientId');
    const createdByCgId = this.requireUuid(payload.createdByCgId, 'createdByCgId');
    const title = this.requireText(payload.title, 'title');
    const startDate = this.requireDate(payload.startDate, 'startDate');
    const endDate = this.optionalDate(payload.endDate, 'endDate');
    this.assertDateOrder(startDate, endDate);
    const items = this.prepareItems(payload.items);

    return this.dataSource.transaction(async (manager) => {
      const saved = await manager.save(
        Prescription,
        manager.create(Prescription, {
          patientId,
          createdByCgId,
          title,
          doctorName: this.optionalText(payload.doctorName),
          prescriptionCode: this.optionalText(payload.prescriptionCode),
          imagePrescriptionUrl: this.optionalText(payload.imagePrescriptionUrl),
          startDate,
          endDate,
          isActive: true,
        }),
      );

      const savedItems = [];
      for (const item of items) {
        savedItems.push(await this.saveItem(manager, saved, item));
      }

      return this.toPrescription(saved, savedItems);
    });
  }

  async list(patientId?: string) {
    const id = this.requireUuid(patientId, 'patientId');
    const rows = await this.prescriptions.find({
      where: { patientId: id },
      relations: { items: { scheduleRules: true } },
      order: { createdAt: 'DESC' },
    });

    return rows.map((row) => this.toPrescriptionFromEntity(row));
  }

  async getById(id: string) {
    return this.toPrescriptionFromEntity(await this.findPrescription(id));
  }

  async update(id: string, payload: UpdatePrescriptionInput) {
    const hasChange = [
      'title',
      'doctorName',
      'prescriptionCode',
      'imagePrescriptionUrl',
      'startDate',
      'endDate',
      'isActive',
    ].some((field) => payload[field as keyof UpdatePrescriptionInput] !== undefined);

    if (!hasChange) {
      throw ErrorHandling.BadRequest('Provide at least one field to update');
    }

    const prescription = await this.findPrescription(id);
    const startDate = payload.startDate !== undefined
      ? this.requireDate(payload.startDate, 'startDate')
      : prescription.startDate;
    const endDate = payload.endDate !== undefined
      ? this.optionalDate(payload.endDate, 'endDate')
      : prescription.endDate;
    this.assertDateOrder(startDate, endDate);

    if (payload.title !== undefined) {
      prescription.title = this.requireText(payload.title, 'title');
    }
    if (payload.doctorName !== undefined) {
      prescription.doctorName = this.optionalText(payload.doctorName);
    }
    if (payload.prescriptionCode !== undefined) {
      prescription.prescriptionCode = this.optionalText(payload.prescriptionCode);
    }
    if (payload.imagePrescriptionUrl !== undefined) {
      prescription.imagePrescriptionUrl = this.optionalText(payload.imagePrescriptionUrl);
    }
    if (payload.isActive !== undefined) {
      prescription.isActive = this.requireBoolean(payload.isActive, 'isActive');
    }
    prescription.startDate = startDate;
    prescription.endDate = endDate;

    const saved = await this.prescriptions.save(prescription);
    saved.items = prescription.items;
    return this.toPrescriptionFromEntity(saved);
  }

  async addItem(prescriptionId: string | undefined, payload: PrescriptionItemInput) {
    const id = this.requireUuid(prescriptionId, 'prescriptionId');
    const [item] = this.prepareItems([payload]);

    return this.dataSource.transaction(async (manager) => {
      const prescription = await manager.findOne(Prescription, { where: { id } });
      if (!prescription) {
        throw ErrorHandling.NotFound('Prescription not found');
      }

      return this.saveItem(manager, prescription, item);
    });
  }

  async updateItem(id: string, payload: UpdatePrescriptionItemInput) {
    const hasChange = [
      'name',
      'genericName',
      'unit',
      'imageUrl',
      'dosagePerTime',
      'currentStock',
      'reorderThreshold',
      'instructions',
    ].some((field) => payload[field as keyof UpdatePrescriptionItemInput] !== undefined);
    if (!hasChange) {
      throw ErrorHandling.BadRequest('Provide at least one field to update');
    }

    const item = await this.findItem(id);
    if (payload.name !== undefined) {
      item.name = this.requireName(payload.name);
    }
    if (payload.genericName !== undefined) {
      item.genericName = this.optionalText(payload.genericName);
    }
    if (payload.unit !== undefined) {
      item.unit = this.requireUnit(payload.unit);
    }
    if (payload.imageUrl !== undefined) {
      item.imageUrl = this.optionalText(payload.imageUrl);
    }
    if (payload.dosagePerTime !== undefined) {
      item.dosagePerTime = this.requireDosage(payload.dosagePerTime);
    }
    if (payload.currentStock !== undefined) {
      item.currentStock = this.requireWholeNumber(payload.currentStock, 'currentStock').toFixed(2);
    }
    if (payload.reorderThreshold !== undefined) {
      item.reorderThreshold = this.requireWholeNumber(payload.reorderThreshold, 'reorderThreshold');
    }
    if (payload.instructions !== undefined) {
      item.instructions = this.optionalText(payload.instructions);
    }

    const saved = await this.prescriptionItems.save(item);
    return this.toItem(saved, item.scheduleRules ?? []);
  }

  async replenishStock(items: Array<{ prescriptionItemId?: string; quantity?: number }> | undefined) {
    if (!items?.length) {
      throw ErrorHandling.BadRequest('Replenish needs at least one item');
    }

    return this.dataSource.transaction(async (manager) => {
      const updated = [];
      for (const item of items) {
        const id = this.requireUuid(item.prescriptionItemId, 'prescriptionItemId');
        const quantity = this.requireWholeNumber(item.quantity ?? -1, 'quantity');
        if (quantity < 1) {
          throw ErrorHandling.BadRequest('quantity must be at least 1');
        }
        const row = await manager.findOne(PrescriptionItem, {
          where: { id },
          lock: { mode: 'pessimistic_write' },
        });
        if (!row) {
          throw ErrorHandling.NotFound('Prescription item not found');
        }
        row.currentStock = (Number(row.currentStock) + quantity).toFixed(2);
        updated.push(await manager.save(PrescriptionItem, row));
      }
      return updated.map((row) => ({
        prescriptionItemId: row.id,
        currentStock: Number(row.currentStock),
      }));
    });
  }

  private async saveItem(
    manager: EntityManager,
    prescription: Pick<Prescription, 'id' | 'patientId' | 'startDate' | 'endDate'>,
    item: PreparedItem,
  ) {
    const savedItem = await manager.save(
      PrescriptionItem,
      manager.create(PrescriptionItem, {
        prescriptionId: prescription.id,
        name: item.name,
        genericName: item.genericName,
        unit: item.unit,
        imageUrl: item.imageUrl,
        dosagePerTime: item.dosagePerTime,
        currentStock: item.currentStock.toFixed(2),
        reorderThreshold: item.reorderThreshold,
        instructions: item.instructions,
      }),
    );

    const savedSchedules = [];
    for (const schedule of item.schedules) {
      const savedSchedule = await manager.save(
        ScheduleRule,
        manager.create(ScheduleRule, {
          prescriptionItemId: savedItem.id,
          patientId: prescription.patientId,
          reminderTime: schedule.reminderTime,
          daysOfWeek: schedule.daysOfWeek,
          isActive: true,
        }),
      );
      await this.saveScheduledLogs(manager, savedSchedule, prescription);
      savedSchedules.push(savedSchedule);
    }

    return this.toItem(savedItem, savedSchedules);
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

  private prepareItems(items: PrescriptionItemInput[] | undefined): PreparedItem[] {
    if (!items?.length) {
      throw ErrorHandling.BadRequest('A prescription needs at least one medicine');
    }

    return items.map((item) => {
      const schedules = item.schedules;
      if (!schedules?.length) {
        throw ErrorHandling.BadRequest('Each medicine needs at least one schedule');
      }

      return {
        name: this.requireName(item.name),
        genericName: this.optionalText(item.genericName),
        unit: this.requireUnit(item.unit),
        imageUrl: this.optionalText(item.imageUrl),
        dosagePerTime: this.requireDosage(item.dosagePerTime),
        currentStock: item.currentStock === undefined ? 0 : this.requireWholeNumber(item.currentStock, 'currentStock'),
        reorderThreshold: item.reorderThreshold === undefined
          ? 6
          : this.requireWholeNumber(item.reorderThreshold, 'reorderThreshold'),
        instructions: this.optionalText(item.instructions),
        schedules: schedules.map((schedule) => ({
          reminderTime: this.requireTime(schedule.reminderTime),
          daysOfWeek: this.normalizeDays(schedule.daysOfWeek),
        })),
      };
    });
  }

  private async findPrescription(id: string) {
    this.requireUuid(id, 'prescription id');
    const prescription = await this.prescriptions.findOne({
      where: { id },
      relations: { items: { scheduleRules: true } },
    });
    if (!prescription) {
      throw ErrorHandling.NotFound('Prescription not found');
    }
    return prescription;
  }

  private async findItem(id: string) {
    this.requireUuid(id, 'prescription item id');
    const item = await this.prescriptionItems.findOne({
      where: { id },
      relations: { scheduleRules: true },
    });
    if (!item) {
      throw ErrorHandling.NotFound('Prescription item not found');
    }
    return item;
  }

  private requireUuid(value: string | undefined, label: string) {
    if (!value || !UUID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be a UUID`);
    }
    return value;
  }

  private requireName(value: string | null | undefined) {
    const trimmed = value?.trim();
    if (!trimmed) {
      throw ErrorHandling.BadRequest('Medicine name is required');
    }
    if (trimmed.length > 200) {
      throw ErrorHandling.BadRequest('Medicine name must be at most 200 characters');
    }
    return trimmed;
  }

  private requireUnit(unit: string | null | undefined): MedicineUnit {
    if (unit !== MedicineUnit.VIEN && unit !== MedicineUnit.GOI && unit !== MedicineUnit.CHAI) {
      throw ErrorHandling.BadRequest('Unit must be VIEN, GOI, or CHAI');
    }
    return unit;
  }

  private requireText(value: string | null | undefined, label: string) {
    const trimmed = value?.trim();
    if (!trimmed) {
      throw ErrorHandling.BadRequest(`${label} is required`);
    }
    return trimmed;
  }

  private optionalText(value: string | null | undefined) {
    if (value == null) {
      return null;
    }
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
  }

  private requireDate(value: string | null | undefined, label: string) {
    const trimmed = value?.trim() ?? '';
    if (!DATE_PATTERN.test(trimmed) || !this.isRealDate(trimmed)) {
      throw ErrorHandling.BadRequest(`${label} must be YYYY-MM-DD`);
    }
    return trimmed;
  }

  private optionalDate(value: string | null | undefined, label: string) {
    if (value == null || value === '') {
      return null;
    }
    return this.requireDate(value, label);
  }

  private isRealDate(value: string) {
    const [year, month, day] = value.split('-').map(Number);
    const date = new Date(Date.UTC(year, month - 1, day));
    return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
  }

  private assertDateOrder(startDate: string, endDate: string | null) {
    if (endDate != null && endDate < startDate) {
      throw ErrorHandling.BadRequest('endDate must be on or after startDate');
    }
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

  private requireDosage(value: number | undefined) {
    if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) {
      throw ErrorHandling.BadRequest('dosagePerTime must be greater than 0');
    }
    return value.toFixed(2);
  }

  private requireWholeNumber(value: number, label: string) {
    if (!Number.isInteger(value) || value < 0) {
      throw ErrorHandling.BadRequest(`${label} must be a whole number of 0 or more`);
    }
    return value;
  }

  private requireBoolean(value: boolean, label: string) {
    if (typeof value !== 'boolean') {
      throw ErrorHandling.BadRequest(`${label} must be true or false`);
    }
    return value;
  }

  private toPrescriptionFromEntity(prescription: Prescription) {
    const items = [...(prescription.items ?? [])]
      .sort((left, right) => left.createdAt.getTime() - right.createdAt.getTime())
      .map((item) => this.toItem(item, item.scheduleRules ?? []));
    return this.toPrescription(prescription, items);
  }

  private toPrescription(
    prescription: Prescription,
    items: ReturnType<PrescriptionsService['toItem']>[],
  ) {
    return {
      id: prescription.id,
      patientId: prescription.patientId,
      createdByCgId: prescription.createdByCgId,
      title: prescription.title,
      doctorName: prescription.doctorName,
      prescriptionCode: prescription.prescriptionCode,
      imagePrescriptionUrl: prescription.imagePrescriptionUrl,
      startDate: prescription.startDate,
      endDate: prescription.endDate,
      isActive: prescription.isActive,
      createdAt: prescription.createdAt,
      updatedAt: prescription.updatedAt,
      items,
    };
  }

  private toItem(item: PrescriptionItem, schedules: ScheduleRule[]) {
    return {
      id: item.id,
      prescriptionId: item.prescriptionId,
      name: item.name,
      genericName: item.genericName,
      unit: item.unit,
      imageUrl: item.imageUrl,
      dosagePerTime: Number(item.dosagePerTime),
      currentStock: Number(item.currentStock),
      reorderThreshold: item.reorderThreshold,
      instructions: item.instructions,
      schedules: [...schedules]
        .sort((left, right) => left.reminderTime.localeCompare(right.reminderTime))
        .map((schedule) => this.toSchedule(schedule)),
    };
  }

  private toSchedule(rule: ScheduleRule) {
    return {
      id: rule.id,
      prescriptionItemId: rule.prescriptionItemId,
      patientId: rule.patientId,
      reminderTime: rule.reminderTime,
      daysOfWeek: rule.daysOfWeek,
      isActive: rule.isActive,
    };
  }
}
