import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { CreateScheduleRuleDto } from './dto/create-schedule-rule.dto.js';
import { ListScheduleRulesQueryDto } from './dto/list-schedule-rules.query.js';
import { UpdateScheduleRuleDto } from './dto/update-schedule-rule.dto.js';

@Injectable()
export class ScheduleRulesService {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
  ) {}

  list(query: ListScheduleRulesQueryDto) {
    return this.send({ cmd: 'list_schedule_rules' }, {
      patientId: query.patientId,
      isActive: query.isActive === undefined ? undefined : query.isActive === 'true',
    });
  }

  getById(id: string) {
    return this.send({ cmd: 'get_schedule_rule' }, { id });
  }

  create(prescriptionItemId: string, dto: CreateScheduleRuleDto) {
    return this.send({ cmd: 'create_schedule_rule' }, { prescriptionItemId, ...dto });
  }

  update(id: string, dto: UpdateScheduleRuleDto) {
    return this.send({ cmd: 'update_schedule_rule' }, { id, ...dto });
  }

  private async send<T>(pattern: { cmd: string }, payload: unknown): Promise<T> {
    try {
      return await lastValueFrom(this.medicationClient.send<T>(pattern, payload));
    } catch (error) {
      throw this.toHttpException(error);
    }
  }

  private toHttpException(error: unknown) {
    if (error instanceof HttpException) {
      return error;
    }

    if (typeof error === 'object' && error !== null) {
      const record = error as { status?: number; message?: unknown };
      if (typeof record.status === 'number' && typeof record.message === 'string') {
        return new HttpException(record.message, record.status);
      }
    }

    return new HttpException('Medication service is unavailable', HttpStatus.SERVICE_UNAVAILABLE);
  }
}
