import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { MedicinesController } from './medicines.controller.js';
import { MedicinesService } from './medicines.service.js';

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
  controllers: [MedicinesController],
  providers: [MedicinesService],
})
export class MedicinesModule {}
