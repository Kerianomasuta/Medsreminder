import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { countsFor, likePattern, numberOrNull, pageWindow, vietnamRange } from '@lib/admin-query';
import { ErrorHandling } from '@lib/error-handling';
import { In, MoreThanOrEqual, Repository } from 'typeorm';
import { DoseStatus } from '../enums/dose-status.enum.js';
import { MedicationLog } from '../medication-logs/schema/medication-log.entity.js';
import { PrescriptionItem } from '../prescriptions/schema/prescription-item.entity.js';
import { Prescription } from '../prescriptions/schema/prescription.entity.js';
import { ScheduleRule } from '../schedule-rules/schema/schedule-rule.entity.js';

const DOSE_STATUSES = Object.values(DoseStatus);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type ListInput = {
  patientId?: string;
  isActive?: boolean;
  status?: string;
  q?: string;
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
};

@Injectable()
export class AdminMedicationService {
  constructor(
    @InjectRepository(Prescription)
    private readonly prescriptions: Repository<Prescription>,
    @InjectRepository(PrescriptionItem)
    private readonly items: Repository<PrescriptionItem>,
    @InjectRepository(ScheduleRule)
    private readonly rules: Repository<ScheduleRule>,
    @InjectRepository(MedicationLog)
    private readonly logs: Repository<MedicationLog>,
  ) {}

  async summary() {
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const [prescriptionTotal, prescriptionActive, prescriptionRecent, itemTotal, lowStock, scheduleTotal, scheduleActive, logRows, logsRecent] = await Promise.all([
      this.prescriptions.count(),
      this.prescriptions.count({ where: { isActive: true } }),
      this.prescriptions.count({ where: { createdAt: MoreThanOrEqual(weekAgo) } }),
      this.items.count(),
      this.items.createQueryBuilder('item').where('item.currentStock <= item.reorderThreshold').getCount(),
      this.rules.count(),
      this.rules.count({ where: { isActive: true } }),
      this.logs.createQueryBuilder('log').select('log.status', 'status').addSelect('COUNT(*)', 'count').groupBy('log.status').getRawMany<Record<string, unknown>>(),
      this.logs.count({ where: { createdAt: MoreThanOrEqual(weekAgo) } }),
    ]);
    const logs = countsFor(DOSE_STATUSES, logRows.map((row) => ({
      key: String(raw(row, 'status') ?? ''),
      count: Number(raw(row, 'count') ?? 0),
    })));
    return {
      prescriptions: {
        total: prescriptionTotal,
        active: prescriptionActive,
        inactive: prescriptionTotal - prescriptionActive,
        createdLast7Days: prescriptionRecent,
      },
      items: { total: itemTotal, lowStock },
      schedules: { total: scheduleTotal, active: scheduleActive, inactive: scheduleTotal - scheduleActive },
      logs: { total: logs.total, byStatus: logs.byStatus, recordedLast7Days: logsRecent },
    };
  }

  async listPrescriptions(input: ListInput) {
    const window = pageWindow(input.page, input.limit);
    const patientId = this.optionalPatient(input.patientId);
    const query = this.prescriptions.createQueryBuilder('prescription').orderBy('prescription.createdAt', 'DESC');
    if (patientId) {
      query.andWhere('prescription.patientId = :patientId', { patientId });
    }
    if (input.isActive === true || input.isActive === false) {
      query.andWhere('prescription.isActive = :isActive', { isActive: input.isActive });
    }
    const pattern = likePattern(input.q);
    if (pattern) {
      query.andWhere(
        `(prescription.title ILIKE :pattern ESCAPE '\\' OR prescription.doctorName ILIKE :pattern ESCAPE '\\' OR prescription.prescriptionCode ILIKE :pattern ESCAPE '\\')`,
        { pattern },
      );
    }
    const [rows, total] = await query.skip(window.skip).take(window.limit).getManyAndCount();
    const itemCounts = await this.itemCounts(rows.map((row) => row.id));
    return {
      page: window.page,
      limit: window.limit,
      total,
      prescriptions: rows.map((row) => ({
        ...this.prescriptionBrief(row),
        itemCount: itemCounts.get(row.id) ?? 0,
      })),
    };
  }

  async prescriptionDetail(id?: string) {
    const prescriptionId = this.requireUuid(id, 'Prescription id is invalid');
    const prescription = await this.prescriptions.findOne({ where: { id: prescriptionId } });
    if (!prescription) {
      throw ErrorHandling.NotFound('Prescription not found');
    }
    const items = await this.items.find({ where: { prescriptionId }, order: { createdAt: 'ASC' } });
    const rules = items.length === 0
      ? []
      : await this.rules.find({ where: { prescriptionItemId: In(items.map((item) => item.id)) }, order: { reminderTime: 'ASC' } });
    return {
      prescription: this.prescriptionBrief(prescription),
      items: items.map((item) => ({
        id: item.id,
        name: item.name,
        genericName: item.genericName,
        unit: item.unit,
        dosagePerTime: numberOrNull(item.dosagePerTime),
        currentStock: numberOrNull(item.currentStock),
        reorderThreshold: item.reorderThreshold,
        instructions: item.instructions,
        schedules: rules
          .filter((rule) => rule.prescriptionItemId === item.id)
          .map((rule) => ({
            id: rule.id,
            reminderTime: rule.reminderTime,
            daysOfWeek: rule.daysOfWeek,
            isActive: rule.isActive,
          })),
      })),
    };
  }

  async listLogs(input: ListInput) {
    const window = pageWindow(input.page, input.limit);
    const patientId = this.optionalPatient(input.patientId);
    if (input.status && !DOSE_STATUSES.includes(input.status as DoseStatus)) {
      throw ErrorHandling.BadRequest('Dose status is not supported');
    }
    const range = vietnamRange(input.from, input.to);
    if ('error' in range) {
      throw ErrorHandling.BadRequest(range.error);
    }
    const query = this.logs.createQueryBuilder('log')
      .leftJoinAndSelect('log.scheduleRule', 'rule')
      .leftJoinAndSelect('rule.prescriptionItem', 'item')
      .orderBy('log.scheduledAt', 'DESC');
    if (patientId) {
      query.andWhere('log.patientId = :patientId', { patientId });
    }
    if (input.status) {
      query.andWhere('log.status = :status', { status: input.status });
    }
    if (range.from) {
      query.andWhere('log.scheduledAt >= :from', { from: range.from });
    }
    if (range.toExclusive) {
      query.andWhere('log.scheduledAt < :to', { to: range.toExclusive });
    }
    const [rows, total] = await query.skip(window.skip).take(window.limit).getManyAndCount();
    return {
      page: window.page,
      limit: window.limit,
      total,
      logs: rows.map((row) => ({
        id: row.id,
        patientId: row.patientId,
        scheduleRuleId: row.scheduleRuleId,
        medicineName: row.scheduleRule?.prescriptionItem?.name ?? null,
        scheduledAt: row.scheduledAt,
        actualTakenAt: row.actualTakenAt,
        status: row.status,
        snoozeUntil: row.snoozeUntil,
        escalationLevel: row.escalationLevel,
        skipReason: row.skipReason,
        createdAt: row.createdAt,
      })),
    };
  }

  private prescriptionBrief(row: Prescription) {
    return {
      id: row.id,
      patientId: row.patientId,
      createdByCgId: row.createdByCgId,
      title: row.title,
      doctorName: row.doctorName,
      prescriptionCode: row.prescriptionCode,
      imagePrescriptionUrl: row.imagePrescriptionUrl,
      startDate: row.startDate,
      endDate: row.endDate,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private async itemCounts(ids: string[]) {
    const counts = new Map<string, number>();
    if (ids.length === 0) {
      return counts;
    }
    const rows = await this.items.createQueryBuilder('item')
      .select('item.prescriptionId', 'prescriptionId')
      .addSelect('COUNT(*)', 'count')
      .where('item.prescriptionId IN (:...ids)', { ids })
      .groupBy('item.prescriptionId')
      .getRawMany<Record<string, unknown>>();
    for (const row of rows) {
      const id = String(raw(row, 'prescriptionId', 'prescriptionid', 'item_prescription_id') ?? '');
      counts.set(id, Number(raw(row, 'count') ?? 0));
    }
    return counts;
  }

  private optionalPatient(patientId?: string) {
    if (!patientId) {
      return undefined;
    }
    if (!/^[0-9a-f]{24}$/i.test(patientId)) {
      throw ErrorHandling.BadRequest('Patient id is invalid');
    }
    return patientId;
  }

  private requireUuid(id: string | undefined, message: string) {
    if (!id || !UUID.test(id)) {
      throw ErrorHandling.BadRequest(message);
    }
    return id;
  }
}

function raw(row: Record<string, unknown>, ...keys: string[]) {
  for (const key of keys) {
    if (row[key] !== undefined && row[key] !== null) {
      return row[key];
    }
  }
  return undefined;
}
