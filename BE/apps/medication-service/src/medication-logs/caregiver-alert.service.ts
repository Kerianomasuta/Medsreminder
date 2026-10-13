import { Inject, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClientProxy } from '@nestjs/microservices';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';
import { lastValueFrom, timeout } from 'rxjs';
import type { DoseLogResponse } from './medication-logs.service.js';

type CaregiverAudience = {
  data?: {
    patientName?: string;
    caregivers?: Array<{ fcmToken?: string }>;
  };
};

const READY_ERROR_CODES = new Set([
  'messaging/invalid-argument',
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

@Injectable()
export class CaregiverAlertService implements OnModuleInit {
  private readonly logger = new Logger(CaregiverAlertService.name);
  private messaging: Messaging | null | undefined;

  constructor(
    @Inject('USER_SERVICE') private readonly users: ClientProxy,
    private readonly config: ConfigService,
  ) {}

  async onModuleInit() {
    let messaging: Messaging | null;
    try {
      messaging = this.client();
    } catch (error) {
      this.messaging = null;
      this.logger.error(`Firebase caregiver alerts failed to start: ${this.errorCode(error) || 'invalid service account'}`);
      return;
    }
    if (!messaging) {
      return;
    }
    try {
      await messaging.send({
        token: `fcm:APA91b${'A'.repeat(140)}`,
        notification: { title: 'setup', body: 'setup' },
      }, true);
      this.logger.log('Firebase caregiver alerts are ready');
    } catch (error) {
      const code = this.errorCode(error);
      if (READY_ERROR_CODES.has(code)) {
        this.logger.log('Firebase caregiver alerts are ready');
        return;
      }
      this.logger.error(`Firebase caregiver alerts failed to start: ${code || 'unknown'}`);
    }
  }

  async notifyClosed(log: DoseLogResponse, status: 'MISSED' | 'SKIPPED') {
    try {
      const audience = await this.request<CaregiverAudience>(
        'list_patient_caregivers',
        { patientId: log.patientId },
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

      if (result.failureCount > 0) {
        this.logger.warn(`Caregiver alert delivered to ${result.successCount} of ${tokens.length} devices`);
      }
      await Promise.all(result.responses.map(async (response, index) => {
        const code = response.error?.code;
        if (!code) {
          return;
        }
        if (
          code !== 'messaging/registration-token-not-registered'
          && code !== 'messaging/invalid-registration-token'
        ) {
          this.logger.warn(`Caregiver alert was rejected: ${code}`);
          return;
        }
        await this.request('clear_fcm_token', { token: tokens[index] }).catch((error: unknown) => {
          this.logger.warn(`Could not clear an expired device token: ${this.errorCode(error) || 'unknown'}`);
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
    const privateKey = this.privateKey(this.config.get<string>('FIREBASE_PRIVATE_KEY'));
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
          privateKey,
        }),
      });
    }
    this.messaging = getMessaging();
    return this.messaging;
  }

  private request<T>(cmd: string, payload: object) {
    return lastValueFrom(this.users.send<T>({ cmd }, payload).pipe(timeout(5000)));
  }

  private privateKey(value: string | undefined) {
    if (!value) {
      return '';
    }
    let key = value.trim();
    if ((key.startsWith('"') && key.endsWith('"')) || (key.startsWith("'") && key.endsWith("'"))) {
      key = key.slice(1, -1);
    }
    return key.replace(/\\n/g, '\n');
  }

  private errorCode(error: unknown) {
    return error && typeof error === 'object' && 'code' in error ? String(error.code) : '';
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
