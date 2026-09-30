import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PrescriptionItem } from './schema/prescription-item.entity.js';
import { Prescription } from './schema/prescription.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Prescription, PrescriptionItem])],
  exports: [TypeOrmModule],
})
export class PrescriptionsModule {}
