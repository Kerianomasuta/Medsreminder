import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventoryModule } from '../inventory/inventory.module.js';
import { PharmaciesModule } from '../pharmacies/pharmacies.module.js';
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';
import { OrderItem } from './schema/order-item.entity.js';
import { Order } from './schema/order.entity.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, OrderItem]),
    PharmaciesModule,
    InventoryModule,
  ],
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
