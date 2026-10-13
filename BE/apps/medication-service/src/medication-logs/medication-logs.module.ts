import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { ScheduleModule } from '@nestjs/schedule';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CaregiverAlertService } from './caregiver-alert.service.js';
import { MedicationLogsController } from './medication-logs.controller.js';
import { DOSE_CLOSED_ALERT, MedicationLogsService } from './medication-logs.service.js';
import { MissedDoseJob } from './missed-dose.job.js';
import { MedicationLog } from './schema/medication-log.entity.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([MedicationLog]),
    ScheduleModule.forRoot(),
    ClientsModule.registerAsync([
      {
        name: 'USER_SERVICE',
        inject: [ConfigService],
        useFactory: (config: ConfigService) => ({
          transport: Transport.TCP,
          options: {
            host: config.get<string>('USER_SERVICE_HOST'),
            port: Number(config.get('USER_SERVICE_PORT')),
          },
        }),
      },
    ]),
  ],
  controllers: [MedicationLogsController],
  providers: [
    MedicationLogsService,
    CaregiverAlertService,
    MissedDoseJob,
    { provide: DOSE_CLOSED_ALERT, useExisting: CaregiverAlertService },
  ],
  exports: [TypeOrmModule],
})
export class MedicationLogsModule {}
