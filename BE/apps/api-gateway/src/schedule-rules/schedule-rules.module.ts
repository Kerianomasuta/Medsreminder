import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { ScheduleRulesController } from './schedule-rules.controller.js';
import { ScheduleRulesService } from './schedule-rules.service.js';

@Module({
  imports: [
    ClientsModule.registerAsync([
      {
        name: 'MEDICATION_SERVICE',
        inject: [ConfigService],
        useFactory: (configService: ConfigService) => ({
          transport: Transport.TCP,
          options: {
            host: configService.get<string>('MEDICATION_SERVICE_HOST'),
            port: configService.get<number>('MEDICATION_SERVICE_PORT'),
          },
        }),
      },
    ]),
  ],
  controllers: [ScheduleRulesController],
  providers: [ScheduleRulesService],
})
export class ScheduleRulesModule {}
