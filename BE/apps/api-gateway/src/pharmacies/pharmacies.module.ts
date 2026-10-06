import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { PharmaciesController } from './pharmacies.controller.js';
import { PharmaciesService } from './pharmacies.service.js';

@Module({
  imports: [
    ClientsModule.registerAsync([
      {
<<<<<<< HEAD
        name: 'PHARMACY_ORDER_SERVICE',
=======
        name: 'PHARMACY_SERVICE',
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
        inject: [ConfigService],
        useFactory: (configService: ConfigService) => ({
          transport: Transport.TCP,
          options: {
<<<<<<< HEAD
            host: configService.get<string>('PHARMACY_ORDER_SERVICE_HOST'),
            port: configService.get<number>('PHARMACY_ORDER_SERVICE_PORT'),
=======
            host: configService.get<string>('PHARMACY_SERVICE_HOST'),
            port: configService.get<number>('PHARMACY_SERVICE_PORT'),
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
          },
        }),
      },
    ]),
  ],
  controllers: [PharmaciesController],
  providers: [PharmaciesService],
<<<<<<< HEAD
  exports: [ClientsModule],
=======
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
})
export class PharmaciesModule {}
