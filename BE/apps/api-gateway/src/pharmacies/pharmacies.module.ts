import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { PharmaciesController } from './pharmacies.controller.js';
import { PharmaciesService } from './pharmacies.service.js';

@Module({
  imports: [
    ClientsModule.registerAsync([
      {
        name: 'PHARMACY_SERVICE',
        inject: [ConfigService],
        useFactory: (configService: ConfigService) => ({
          transport: Transport.TCP,
          options: {
            host: configService.get<string>('PHARMACY_SERVICE_HOST'),
            port: configService.get<number>('PHARMACY_SERVICE_PORT'),
          },
        }),
      },
    ]),
  ],
  controllers: [PharmaciesController],
  providers: [PharmaciesService],
})
export class PharmaciesModule {}
