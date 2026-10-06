import { Module } from '@nestjs/common';
<<<<<<< HEAD
import { PharmaciesModule } from '../pharmacies/pharmacies.module.js';
=======
import { ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';

@Module({
<<<<<<< HEAD
  imports: [PharmaciesModule],
=======
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
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
