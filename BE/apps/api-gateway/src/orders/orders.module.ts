import { Module } from '@nestjs/common';
import { PharmaciesModule } from '../pharmacies/pharmacies.module.js';
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';

@Module({
  imports: [PharmaciesModule],
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
