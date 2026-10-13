import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThanOrEqual, Repository } from 'typeorm';
import { DoseStatus } from '../enums/dose-status.enum.js';
import { MISSED_AFTER_MS, MedicationLogsService } from './medication-logs.service.js';
import { MedicationLog } from './schema/medication-log.entity.js';

@Injectable()
export class MissedDoseJob implements OnModuleInit {
  private readonly logger = new Logger(MissedDoseJob.name);

  constructor(
    @InjectRepository(MedicationLog)
    private readonly logs: Repository<MedicationLog>,
    private readonly medicationLogs: MedicationLogsService,
  ) {}

  onModuleInit() {
    this.logger.log('Missed-dose sweep is scheduled every minute');
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async sweep() {
    const deadline = new Date(Date.now() - MISSED_AFTER_MS);
    const due = await this.logs.find({
      where: [
        { status: DoseStatus.SCHEDULED, scheduledAt: LessThanOrEqual(deadline) },
        { status: DoseStatus.SNOOZED, snoozeUntil: LessThanOrEqual(deadline) },
      ],
      take: 100,
    });
    for (const row of due) {
      try {
        await this.medicationLogs.markMissedBySystem(row.id);
      } catch (error) {
        this.logger.error(`Could not mark dose ${row.id} missed`, error instanceof Error ? error.stack : String(error));
      }
    }
  }
}
