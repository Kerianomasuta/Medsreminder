import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { toRpcHttpException } from '../rpc-http-exception.js';
import { CreateScheduleRuleDto } from './dto/create-schedule-rule.dto.js';
import { ListScheduleRulesQueryDto } from './dto/list-schedule-rules.query.js';
import { UpdateScheduleRuleDto } from './dto/update-schedule-rule.dto.js';

type AccessUser = {
  userId: string;
  role: string;
};

@Injectable()
export class ScheduleRulesService {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
  ) {}

  list(query: ListScheduleRulesQueryDto, user: AccessUser) {
    return this.send({ cmd: 'list_schedule_rules' }, {
      patientId: query.patientId,
      isActive: query.isActive === undefined ? undefined : query.isActive === 'true',
      ...this.actor(user),
    });
  }

  getById(id: string, user: AccessUser) {
    return this.send({ cmd: 'get_schedule_rule' }, { id, ...this.actor(user) });
  }

  create(prescriptionItemId: string, dto: CreateScheduleRuleDto, user: AccessUser) {
    return this.send({ cmd: 'create_schedule_rule' }, { prescriptionItemId, ...dto, ...this.actor(user) });
  }

  update(id: string, dto: UpdateScheduleRuleDto, user: AccessUser) {
    return this.send({ cmd: 'update_schedule_rule' }, { id, ...dto, ...this.actor(user) });
  }

  private actor(user: AccessUser) {
    return { actorUserId: user.userId, actorRole: user.role };
  }

  private async send<T>(pattern: { cmd: string }, payload: unknown): Promise<T> {
    try {
      return await lastValueFrom(this.medicationClient.send<T>(pattern, payload));
    } catch (error) {
      throw this.toHttpException(error);
    }
  }

  private toHttpException(error: unknown) {
    return toRpcHttpException(error, 'Medication service is unavailable');
  }
}
