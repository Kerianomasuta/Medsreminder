import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClientProxy } from '@nestjs/microservices';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';
import { lastValueFrom } from 'rxjs';
import type { DoseLogResponse } from './medication-logs.service.js';

type CaregiverAudience = {
  data?: {
    patientName?: string;
    caregivers?: Array<{ fcmToken?: string }>;
  };
};

@Injectable()
export class CaregiverAlertService {
  private readonly logger = new Logger(CaregiverAlertService.name);
  private messaging: Messaging | null | undefined;

  constructor(
    @Inject('USER_SERVICE') private readonly users: ClientProxy,
    private readonly config: ConfigService,
  ) {}

  async notifyClosed(log: DoseLogResponse, status: 'MISSED' | 'SKIPPED') {
    try {
      const audience = await lastValueFrom(
        this.users.send<CaregiverAudience>({ cmd: 'list_patient_caregivers' }, { patientId: log.patientId }),
      );
      const caregivers = audience?.data?.caregivers ?? [];
      const tokens = caregivers
        .map((caregiver) => caregiver.fcmToken)
        .filter((token): token is string => Boolean(token));
      if (tokens.length === 0) {
        return;
      }

      const messaging = this.client();
      if (!messaging) {
        return;
      }

      const medicine = log.medicine?.name ?? 'thuốc';
      const patientName = audience?.data?.patientName || 'Bệnh nhân';
      const result = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: status === 'MISSED' ? 'Quên uống thuốc' : 'Đã bỏ qua thuốc',
          body: `${patientName} · ${medicine} lúc ${this.clock(log.scheduledAt)}`,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'caregiver_alerts',
            priority: 'max',
            visibility: 'public',
          },
        },
        data: {
          type: 'DOSE_ALERT',
          logId: log.id,
          status,
        },
      });

      await Promise.all(result.responses.map(async (response, index) => {
        const code = response.error?.code;
        if (
          code !== 'messaging/registration-token-not-registered'
          && code !== 'messaging/invalid-registration-token'
        ) {
          return;
        }
        await lastValueFrom(
          this.users.send({ cmd: 'clear_fcm_token' }, { token: tokens[index] }),
        ).catch((error: unknown) => {
          this.logger.warn(`Could not clear an expired device token: ${String(error)}`);
        });
      }));
    } catch (error) {
      this.logger.error(
        `Could not alert caregivers for dose ${log.id}`,
        error instanceof Error ? error.stack : String(error),
      );
    }
  }

  private client() {
    if (this.messaging !== undefined) {
      return this.messaging;
    }
    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = this.config.get<string>('FIREBASE_PRIVATE_KEY');
    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn('Firebase is not configured, so caregiver alerts are skipped');
      this.messaging = null;
      return null;
    }
    if (getApps().length === 0) {
      initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey: privateKey.replace(/\\n/g, '\n'),
        }),
      });
    }
    this.messaging = getMessaging();
    return this.messaging;
  }

  private clock(value: Date | string) {
    return new Intl.DateTimeFormat('en-GB', {
      timeZone: 'Asia/Ho_Chi_Minh',
      hour: '2-digit',
      minute: '2-digit',
      hourCycle: 'h23',
    }).format(new Date(value));
  }
}
