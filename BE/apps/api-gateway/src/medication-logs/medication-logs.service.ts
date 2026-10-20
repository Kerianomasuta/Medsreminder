import { ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { toRpcHttpException } from '../rpc-http-exception.js';
import { ComplianceReportQueryDto, ListMedicationLogsQueryDto, RecordDoseDto, SkipDoseDto, SnoozeDoseDto } from './dto/medication-log.dto.js';

type AccessUser = {
  userId: string;
  role: string;
  fullName?: string;
};

@Injectable()
export class MedicationLogsService {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
    @Inject('USER_SERVICE')
    private readonly userClient: ClientProxy,
  ) {}

  async complianceReport(query: ComplianceReportQueryDto, user: AccessUser) {
    if (user.role !== 'ADMIN') {
      const premium = await this.sendTo<{ isPremium?: boolean }>(
        this.userClient,
        { cmd: 'handle_get_premium' },
        { userId: user.userId },
        'User service is unavailable',
      );
      if (premium?.isPremium !== true) {
        throw new ForbiddenException('A compliance report requires a premium account');
      }
    }
    const patientName = user.role === 'PATIENT'
      ? user.fullName ?? ''
      : await this.patientName(query.patientId);
    return this.send<{ filename: string; pdfBase64: string }>(
      { cmd: 'compliance_report' },
      {
        patientId: query.patientId,
        actorUserId: user.userId,
        actorRole: user.role,
        patientName,
      },
    );
  }

  list(query: ListMedicationLogsQueryDto, user: AccessUser) {
    return this.send({ cmd: 'list_medication_logs' }, {
      patientId: query.patientId,
      actorUserId: user.userId,
      actorRole: user.role,
      from: query.from,
      to: query.to,
    });
  }

  take(id: string, user: AccessUser) {
    return this.send({ cmd: 'take_medication_log' }, { id, userId: user.userId });
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

  private async patientName(patientId?: string) {
    if (!patientId) {
      return '';
    }
    try {
      const detail = await this.sendTo<{ data?: { patient?: { fullName?: unknown } } }>(
        this.userClient,
        { cmd: 'handle_get_patient_detail' },
        { patientId },
        'User service is unavailable',
      );
      return typeof detail?.data?.patient?.fullName === 'string' ? detail.data.patient.fullName : '';
    } catch {
      return '';
    }
  }

  private send<T>(pattern: { cmd: string }, payload: unknown) {
    return this.sendTo<T>(this.medicationClient, pattern, payload, 'Medication service is unavailable');
  }

  private async sendTo<T>(
    client: ClientProxy,
    pattern: { cmd: string },
    payload: unknown,
    unavailableMessage: string,
  ): Promise<T> {
    try {
      return await lastValueFrom(client.send<T>(pattern, payload));
    } catch (error) {
      throw toRpcHttpException(error, unavailableMessage);
    }
  }
}
