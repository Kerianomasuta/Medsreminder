import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PharmaciesModule } from '../pharmacies/pharmacies.module.js';
import { InventoryController } from './inventory.controller.js';
import { InventoryService } from './inventory.service.js';
import { PharmacyInventory } from './schema/pharmacy-inventory.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([PharmacyInventory]), PharmaciesModule],
  controllers: [InventoryController],
  providers: [InventoryService],
  exports: [TypeOrmModule],
})
export class InventoryModule {}
