import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PharmaciesController } from './pharmacies.controller.js';
import { PharmaciesService } from './pharmacies.service.js';
<<<<<<< HEAD
import { PharmacyInventory } from './schema/pharmacy-inventory.entity.js';
import { Pharmacy } from './schema/pharmacy.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Pharmacy, PharmacyInventory])],
=======
import { Pharmacy } from './schema/pharmacy.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Pharmacy])],
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  controllers: [PharmaciesController],
  providers: [PharmaciesService],
  exports: [TypeOrmModule],
})
export class PharmaciesModule {}
