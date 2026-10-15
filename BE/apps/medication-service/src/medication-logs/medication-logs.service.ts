import { Inject, Injectable, Optional } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { And, DataSource, EntityManager, LessThan, MoreThanOrEqual, Raw, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import {
  buildComplianceReport,
  renderComplianceHtml,
  renderCompliancePdf,
  REPORT_DAYS,
  type ComplianceDose,
  type ComplianceMedicineLine,
} from './compliance-report.js';
import { DoseStatus } from '../enums/dose-status.enum.js';
import { ScheduleRule } from '../schedule-rules/schema/schedule-rule.entity.js';
import { MedicationLog } from './schema/medication-log.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const OBJECT_ID_PATTERN = /^[0-9a-f]{24}$/i;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const VIETNAM_OFFSET_MS = 7 * 60 * 60 * 1000;
export const MISSED_AFTER_MS = 11 * 60 * 1000;
export const DOSE_CLOSED_ALERT = Symbol('DOSE_CLOSED_ALERT');

export type DoseClosedAlert = {
  notifyClosed(log: DoseLogResponse, status: 'MISSED' | 'SKIPPED'): Promise<void>;
};

export type DoseLogResponse = {
  id: string;
  scheduleRuleId: string;
  patientId: string;
  scheduledAt: Date;
  actualTakenAt: Date | null;
  status: DoseStatus;
  snoozeUntil: Date | null;
  escalationLevel: number;
  skipReason: string | null;
  dosagePerTime: number | null;
  instructions: string | null;
  medicine: {
    name: string;
    genericName: string | null;
    unit: string;
    imageUrl: string | null;
  } | null;
};
const CLOCK_SKEW_MS = 2 * 60 * 1000;
const OPEN_STATUSES = new Set<DoseStatus>([DoseStatus.SCHEDULED, DoseStatus.SNOOZED]);

export type ListLogsInput = {
  patientId?: string;
  actorUserId?: string;
  actorRole?: string;
  from?: string;
  to?: string;
};

export type DoseActionInput = {
  userId?: string;
  actedAt?: string | null;
  minutes?: number;
  skipReason?: string | null;
};

@Injectable()
export class MedicationLogsService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(MedicationLog)
    private readonly logs: Repository<MedicationLog>,
    @Optional() @Inject(DOSE_CLOSED_ALERT) private readonly alerts?: DoseClosedAlert,
  ) {}

  async list(input: ListLogsInput = {}) {
    const patientId = this.listPatientId(input);
    const from = input.from === undefined ? this.today() : this.requireDate(input.from, 'from');
    const to = input.to === undefined ? undefined : this.requireDate(input.to, 'to');
    if (to !== undefined && to < from) {
      throw ErrorHandling.BadRequest('to must be on or after from');
    }

    const fromInstant = this.startOfVietnamDay(from);
    const scheduledAt = to === undefined
      ? MoreThanOrEqual(fromInstant)
      : And(MoreThanOrEqual(fromInstant), LessThan(this.startOfVietnamDay(this.addDays(to, 1))));

    const rows = await this.logs.find({
      where: {
        patientId: Raw((alias) => `LOWER(${alias}) = :patientId`, { patientId }),
        scheduledAt,
      },
      relations: { scheduleRule: { prescriptionItem: true } },
      order: { scheduledAt: 'ASC' },
    });
    return rows.map((row) => this.toResponse(row));
  }

  async complianceReport(input: ListLogsInput & { patientName?: string } = {}) {
    const patientId = this.reportPatientId(input);
    const today = this.today();
    const from = this.addDays(today, -(REPORT_DAYS - 1));
    const fromInstant = this.startOfVietnamDay(from);
    const toInstant = this.startOfVietnamDay(this.addDays(today, 1));
    const doses = await this.dataSource.query(
      `SELECT l.status AS status,
              l.scheduled_at AS scheduled_at,
              l.actual_taken_at AS actual_taken_at,
              l.snooze_until AS snooze_until,
              i.name AS medicine_name
       FROM medication.medication_logs l
       INNER JOIN medication.schedule_rules r ON r.id = l.schedule_rule_id
       INNER JOIN medication.prescription_items i ON i.id = r.prescription_item_id
       WHERE LOWER(l.patient_id) = $1
         AND l.scheduled_at >= $2
         AND l.scheduled_at < $3
       ORDER BY l.scheduled_at ASC`,
      [patientId, fromInstant, toInstant],
    ) as Array<Record<string, unknown>>;
    const lines = await this.dataSource.query(
      `SELECT p.id AS prescription_id,
              p.title AS title,
              p.doctor_name AS doctor_name,
              p.start_date AS start_date,
              p.end_date AS end_date,
              i.name AS medicine_name,
              i.dosage_per_time AS dosage_per_time,
              i.unit AS unit,
              r.reminder_time AS reminder_time
       FROM medication.prescriptions p
       INNER JOIN medication.prescription_items i ON i.prescription_id = p.id
       LEFT JOIN medication.schedule_rules r
         ON r.prescription_item_id = i.id AND r.is_active = true
       WHERE LOWER(p.patient_id) = $1
         AND p.is_active = true
         AND p.start_date <= $2::date
         AND (p.end_date IS NULL OR p.end_date >= $2::date)
       ORDER BY p.created_at ASC, i.created_at ASC, r.reminder_time ASC`,
      [patientId, today],
    ) as Array<Record<string, unknown>>;
    const report = buildComplianceReport({
      patientName: input.patientName ?? '',
      from,
      to: today,
      now: new Date(),
      doses: doses.map((row) => this.toComplianceDose(row)),
      lines: lines.map((row) => this.toComplianceLine(row)),
    });
    const pdf = await renderCompliancePdf(renderComplianceHtml(report));
    return {
      filename: `bao-cao-tuan-thu-${from}-den-${today}.pdf`,
      pdfBase64: pdf.toString('base64'),
    };
  }

  async take(id: string, input: DoseActionInput = {}) {
    const actedAt = this.resolveActedAt(input.actedAt);
    return this.change(id, input.userId, (log) => {
      log.status = DoseStatus.TAKEN;
      log.actualTakenAt = actedAt;
      log.snoozeUntil = null;
      log.skipReason = null;
    });
  }

  async snooze(id: string, input: DoseActionInput = {}) {
    if (input.minutes !== 5 && input.minutes !== 10) {
      throw ErrorHandling.BadRequest('minutes must be 5 or 10');
    }
    const actedAt = this.resolveActedAt(input.actedAt);
    const snoozeUntil = new Date(actedAt.getTime() + input.minutes * 60 * 1000);
    return this.change(id, input.userId, (log) => {
      log.status = DoseStatus.SNOOZED;
      log.snoozeUntil = snoozeUntil;
      log.actualTakenAt = null;
      log.skipReason = null;
    });
  }

  async skip(id: string, input: DoseActionInput = {}) {
    const reason = this.optionalReason(input.skipReason);
    this.resolveActedAt(input.actedAt);
    const saved = await this.change(id, input.userId, (log) => {
      log.status = DoseStatus.SKIPPED;
      log.skipReason = reason;
      log.snoozeUntil = null;
      log.actualTakenAt = null;
      log.escalationLevel = 1;
    });
    await this.notify(saved, 'SKIPPED');
    return saved;
  }

  async miss(id: string, input: DoseActionInput = {}) {
    const actedAt = this.resolveActedAt(input.actedAt);
    const saved = await this.change(id, input.userId, (log) => {
      const dueAt = new Date(this.currentReminder(log).getTime() + MISSED_AFTER_MS);
      if (actedAt.getTime() < dueAt.getTime()) {
        throw ErrorHandling.BadRequest('A dose can be marked missed only 11 minutes after the current reminder');
      }
      this.applyMissed(log);
    });
    await this.notify(saved, 'MISSED');
    return saved;
  }

  async markMissedBySystem(id: string) {
    const saved = await this.dataSource.transaction(async (manager) => {
      const log = await this.lockLog(manager, id);
      if (!OPEN_STATUSES.has(log.status)) {
        return null;
      }
      if (Date.now() < this.currentReminder(log).getTime() + MISSED_AFTER_MS) {
        return null;
      }
      this.applyMissed(log);
      const savedLog = await manager.save(MedicationLog, log);
      savedLog.scheduleRule = log.scheduleRule;
      return this.toResponse(savedLog);
    });
    if (!saved) {
      return null;
    }
    await this.notify(saved, 'MISSED');
    return saved;
  }

  private applyMissed(log: MedicationLog) {
    log.status = DoseStatus.MISSED;
    log.snoozeUntil = null;
    log.actualTakenAt = null;
    log.skipReason = null;
    log.escalationLevel = 1;
  }

  private async notify(log: DoseLogResponse, status: 'MISSED' | 'SKIPPED') {
    try {
      await this.alerts?.notifyClosed(log, status);
    } catch (error) {
      console.error(`Could not alert caregivers for dose ${log.id}`, error);
    }
  }

  private async change(id: string, userId: string | undefined, apply: (log: MedicationLog) => void) {
    const patientId = this.requireObjectId(userId, 'userId');
    return this.dataSource.transaction(async (manager) => {
      const log = await this.lockLog(manager, id);
      if (log.patientId.toLowerCase() !== patientId) {
        throw ErrorHandling.Forbidden('A patient can only record their own dose');
      }
      if (!OPEN_STATUSES.has(log.status)) {
        throw ErrorHandling.BadRequest('This dose can no longer be changed');
      }
      apply(log);
      const saved = await manager.save(MedicationLog, log);
      saved.scheduleRule = log.scheduleRule;
      return this.toResponse(saved);
    });
  }

  private reportPatientId(actor: ListLogsInput) {
    if (actor.actorRole === 'PATIENT') {
      return this.requireObjectId(actor.actorUserId, 'actorUserId');
    }
    if (actor.actorRole === 'CARE_GIVER' || actor.actorRole === 'ADMIN') {
      return this.requireObjectId(actor.patientId, 'patientId');
    }
    throw ErrorHandling.Forbidden('Only patients, caregivers, and admins can export a compliance report');
  }

  private toComplianceDose(row: Record<string, unknown>): ComplianceDose {
    return {
      medicineName: textValue(row.medicine_name),
      status: textValue(row.status),
      scheduledAt: instantValue(row.scheduled_at),
      actualTakenAt: optionalInstant(row.actual_taken_at),
      snoozeUntil: optionalInstant(row.snooze_until),
    };
  }

  private toComplianceLine(row: Record<string, unknown>): ComplianceMedicineLine {
    return {
      prescriptionId: textValue(row.prescription_id),
      title: textValue(row.title),
      doctorName: textValue(row.doctor_name) || null,
      startDate: dateValue(row.start_date),
      endDate: dateValue(row.end_date) || null,
      medicineName: textValue(row.medicine_name),
      dosage: textValue(row.dosage_per_time),
      unit: textValue(row.unit),
      reminderTime: textValue(row.reminder_time) || null,
    };
  }

  private listPatientId(actor: ListLogsInput) {
    if (actor.actorRole === 'PATIENT') {
      return this.requireObjectId(actor.actorUserId, 'actorUserId');
    }
    if (actor.actorRole === 'CARE_GIVER') {
      return this.requireObjectId(actor.patientId, 'patientId');
    }
    throw ErrorHandling.Forbidden('Only patients and caregivers can access medication logs');
  }

  private async lockLog(manager: EntityManager, id: string) {
    const logId = this.requireUuid(id, 'log id');
    const log = await manager.findOne(MedicationLog, {
      where: { id: logId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!log) {
      throw ErrorHandling.NotFound('Dose log not found');
    }
    const scheduleRule = await manager.findOne(ScheduleRule, {
      where: { id: log.scheduleRuleId },
      relations: { prescriptionItem: true },
    });
    if (scheduleRule) {
      log.scheduleRule = scheduleRule;
    }
    return log;
  }

  private currentReminder(log: MedicationLog) {
    if (log.status === DoseStatus.SNOOZED && log.snoozeUntil) {
      return this.asDate(log.snoozeUntil);
    }
    return this.asDate(log.scheduledAt);
  }

  private asDate(value: Date | string) {
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw ErrorHandling.BadRequest('The dose reminder time is invalid');
    }
    return date;
  }

  private toResponse(log: MedicationLog): DoseLogResponse {
    const item = log.scheduleRule?.prescriptionItem;
    return {
      id: log.id,
      scheduleRuleId: log.scheduleRuleId,
      patientId: log.patientId,
      scheduledAt: log.scheduledAt,
      actualTakenAt: log.actualTakenAt,
      status: log.status,
      snoozeUntil: log.snoozeUntil,
      escalationLevel: log.escalationLevel,
      skipReason: log.skipReason,
      dosagePerTime: item ? Number(item.dosagePerTime) : null,
      instructions: item?.instructions ?? null,
      medicine: item ? {
        name: item.name,
        genericName: item.genericName,
        unit: item.unit,
        imageUrl: item.imageUrl,
      } : null,
    };
  }

  private resolveActedAt(value?: string | null) {
    if (value == null) {
      return new Date();
    }
    if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,3})?)?(Z|[+-]\d{2}:\d{2})$/.test(value)) {
      throw ErrorHandling.BadRequest('actedAt must be an ISO-8601 time with a timezone');
    }
    const actedAt = new Date(value);
    if (Number.isNaN(actedAt.getTime())) {
      throw ErrorHandling.BadRequest('actedAt must be an ISO-8601 time');
    }
    if (actedAt.getTime() > Date.now() + CLOCK_SKEW_MS) {
      throw ErrorHandling.BadRequest('actedAt cannot be in the future');
    }
    return actedAt;
  }

  private optionalReason(value: string | null | undefined) {
    if (value == null) {
      return null;
    }
    const trimmed = value.trim();
    if (!trimmed) {
      return null;
    }
    if (trimmed.length > 500) {
      throw ErrorHandling.BadRequest('skipReason must be at most 500 characters');
    }
    return trimmed;
  }

  private today(now = new Date()) {
    return new Date(now.getTime() + VIETNAM_OFFSET_MS).toISOString().slice(0, 10);
  }

  private startOfVietnamDay(isoDate: string) {
    return new Date(`${isoDate}T00:00:00+07:00`);
  }

  private addDays(isoDate: string, days: number) {
    const [year, month, day] = isoDate.split('-').map(Number);
    const date = new Date(Date.UTC(year, month - 1, day + days));
    const nextMonth = String(date.getUTCMonth() + 1).padStart(2, '0');
    const nextDay = String(date.getUTCDate()).padStart(2, '0');
    return `${date.getUTCFullYear()}-${nextMonth}-${nextDay}`;
  }

  private requireDate(value: string, label: string) {
    if (!DATE_PATTERN.test(value) || !this.isRealDate(value)) {
      throw ErrorHandling.BadRequest(`${label} must be YYYY-MM-DD`);
    }
    return value;
  }

  private isRealDate(value: string) {
    const [year, month, day] = value.split('-').map(Number);
    const date = new Date(Date.UTC(year, month - 1, day));
    return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
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
    return value.toLowerCase();
  }
}

function textValue(value: unknown) {
  if (value == null) {
    return '';
  }
  return String(value);
}

function instantValue(value: unknown) {
  const instant = optionalInstant(value);
  return instant ?? new Date(0);
}

function optionalInstant(value: unknown) {
  if (value == null || value === '') {
    return null;
  }
  const instant = value instanceof Date ? value : new Date(String(value));
  return Number.isNaN(instant.getTime()) ? null : instant;
}

function dateValue(value: unknown) {
  if (value instanceof Date) {
    const month = String(value.getUTCMonth() + 1).padStart(2, '0');
    const day = String(value.getUTCDate()).padStart(2, '0');
    return `${value.getUTCFullYear()}-${month}-${day}`;
  }
  const match = String(value ?? '').match(/^(\d{4}-\d{2}-\d{2})/);
  return match?.[1] ?? '';
}
