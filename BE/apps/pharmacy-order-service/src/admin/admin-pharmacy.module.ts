import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrderItem } from '../orders/schema/order-item.entity.js';
import { Order } from '../orders/schema/order.entity.js';
import { Pharmacy } from '../pharmacies/schema/pharmacy.entity.js';
import { AdminPharmacyController } from './admin-pharmacy.controller.js';
import { AdminPharmacyService } from './admin-pharmacy.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([Pharmacy, Order, OrderItem])],
  controllers: [AdminPharmacyController],
  providers: [AdminPharmacyService],
})
export class AdminPharmacyModule {}
