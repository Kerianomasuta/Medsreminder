import { Module } from '@nestjs/common';
<<<<<<< HEAD
import { ConfigService } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MedicationStockClient } from './medication-stock.client.js';
=======
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventoryModule } from '../inventory/inventory.module.js';
import { PharmaciesModule } from '../pharmacies/pharmacies.module.js';
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';
import { OrderItem } from './schema/order-item.entity.js';
import { Order } from './schema/order.entity.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, OrderItem]),
<<<<<<< HEAD
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
  controllers: [OrdersController],
  providers: [OrdersService, MedicationStockClient],
=======
    PharmaciesModule,
    InventoryModule,
  ],
  controllers: [OrdersController],
  providers: [OrdersService],
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
})
export class OrdersModule {}
