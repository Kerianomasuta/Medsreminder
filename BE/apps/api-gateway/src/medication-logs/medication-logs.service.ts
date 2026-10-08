import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { toRpcHttpException } from '../rpc-http-exception.js';
import { ListMedicationLogsQueryDto, RecordDoseDto, SkipDoseDto, SnoozeDoseDto } from './dto/medication-log.dto.js';

type AccessUser = {
  userId: string;
  role: string;
};

@Injectable()
export class MedicationLogsService {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
  ) {}

  list(query: ListMedicationLogsQueryDto, user: AccessUser) {
    return this.send({ cmd: 'list_medication_logs' }, {
      userId: user.userId,
      from: query.from,
      to: query.to,
    });
  }

  take(id: string, dto: RecordDoseDto, user: AccessUser) {
    return this.send({ cmd: 'take_medication_log' }, { id, actedAt: dto.actedAt, userId: user.userId });
  }

  snooze(id: string, dto: SnoozeDoseDto, user: AccessUser) {
    return this.send({ cmd: 'snooze_medication_log' }, {
      id,
      minutes: dto.minutes,
      actedAt: dto.actedAt,
      userId: user.userId,
    });
  }

  skip(id: string, dto: SkipDoseDto, user: AccessUser) {
    return this.send({ cmd: 'skip_medication_log' }, {
      id,
      skipReason: dto.skipReason,
      actedAt: dto.actedAt,
      userId: user.userId,
    });
  }

  miss(id: string, dto: RecordDoseDto, user: AccessUser) {
    return this.send({ cmd: 'miss_medication_log' }, { id, actedAt: dto.actedAt, userId: user.userId });
  }

  private async send<T>(pattern: { cmd: string }, payload: unknown): Promise<T> {
    try {
      return await lastValueFrom(this.medicationClient.send<T>(pattern, payload));
    } catch (error) {
      throw toRpcHttpException(error, 'Medication service is unavailable');
    }
  }
}
