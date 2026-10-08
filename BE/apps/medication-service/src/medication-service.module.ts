import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MedicationLogsModule } from './medication-logs/medication-logs.module.js';
import { PrescriptionsModule } from './prescriptions/prescriptions.module.js';
import { ScheduleRulesModule } from './schedule-rules/schedule-rules.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/medication-service/.env',
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        url: config.getOrThrow<string>('MEDICATION_DATABASE_URL'),
        schema: config.get<string>('MEDICATION_DB_SCHEMA', 'medication'),
        autoLoadEntities: true,
        synchronize: false,
        ssl: { rejectUnauthorized: false },
      }),
    }),
    PrescriptionsModule,
    ScheduleRulesModule,
    MedicationLogsModule,
  ],
})
export class MedicationServiceModule {}
