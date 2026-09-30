import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { Medicine } from '../medicines/schema/medicine.entity.js';
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
  medicineId?: string;
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
  startDate?: string;
  endDate?: string | null;
  items?: PrescriptionItemInput[];
};

export type UpdatePrescriptionInput = {
  title?: string;
  doctorName?: string | null;
  prescriptionCode?: string | null;
  startDate?: string;
  endDate?: string | null;
  isActive?: boolean;
};

export type UpdatePrescriptionItemInput = {
  dosagePerTime?: number;
  currentStock?: number;
  reorderThreshold?: number;
  instructions?: string | null;
};

type PreparedItem = {
  medicineId: string;
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
      await this.assertMedicinesExist(manager, items);

      const saved = await manager.save(
        Prescription,
        manager.create(Prescription, {
          patientId,
          createdByCgId,
          title,
          doctorName: this.optionalText(payload.doctorName),
          prescriptionCode: this.optionalText(payload.prescriptionCode),
          startDate,
          endDate,
          isActive: true,
        }),
      );

      const savedItems = [];
      for (const item of items) {
        savedItems.push(await this.saveItem(manager, saved.id, patientId, item));
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

      await this.assertMedicinesExist(manager, [item]);
      return this.saveItem(manager, prescription.id, prescription.patientId, item);
    });
  }

  async updateItem(id: string, payload: UpdatePrescriptionItemInput) {
    const hasChange = ['dosagePerTime', 'currentStock', 'reorderThreshold', 'instructions'].some(
      (field) => payload[field as keyof UpdatePrescriptionItemInput] !== undefined,
    );
    if (!hasChange) {
      throw ErrorHandling.BadRequest('Provide at least one field to update');
    }

    const item = await this.findItem(id);
    if (payload.dosagePerTime !== undefined) {
      item.dosagePerTime = this.requireDosage(payload.dosagePerTime);
    }
    if (payload.currentStock !== undefined) {
      item.currentStock = this.requireWholeNumber(payload.currentStock, 'currentStock');
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

  private async saveItem(
    manager: EntityManager,
    prescriptionId: string,
    patientId: string,
    item: PreparedItem,
  ) {
    const savedItem = await manager.save(
      PrescriptionItem,
      manager.create(PrescriptionItem, {
        prescriptionId,
        medicineId: item.medicineId,
        dosagePerTime: item.dosagePerTime,
        currentStock: item.currentStock,
        reorderThreshold: item.reorderThreshold,
        instructions: item.instructions,
      }),
    );

    const savedSchedules = [];
    for (const schedule of item.schedules) {
      savedSchedules.push(
        await manager.save(
          ScheduleRule,
          manager.create(ScheduleRule, {
            prescriptionItemId: savedItem.id,
            patientId,
            reminderTime: schedule.reminderTime,
            daysOfWeek: schedule.daysOfWeek,
            isActive: true,
          }),
        ),
      );
    }

    return this.toItem(savedItem, savedSchedules);
  }

  private async assertMedicinesExist(manager: EntityManager, items: PreparedItem[]) {
    for (const item of items) {
      const medicine = await manager.findOne(Medicine, { where: { id: item.medicineId } });
      if (!medicine) {
        throw ErrorHandling.NotFound('Medicine not found');
      }
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
        medicineId: this.requireUuid(item.medicineId, 'medicineId'),
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
      medicineId: item.medicineId,
      dosagePerTime: Number(item.dosagePerTime),
      currentStock: item.currentStock,
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
