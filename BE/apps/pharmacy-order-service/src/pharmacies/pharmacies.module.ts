import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PharmaciesController } from './pharmacies.controller.js';
import { PharmaciesService } from './pharmacies.service.js';
import { PharmacyInventory } from './schema/pharmacy-inventory.entity.js';
import { Pharmacy } from './schema/pharmacy.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Pharmacy, PharmacyInventory])],
  controllers: [PharmaciesController],
  providers: [PharmaciesService],
  exports: [TypeOrmModule],
})
export class PharmaciesModule {}
