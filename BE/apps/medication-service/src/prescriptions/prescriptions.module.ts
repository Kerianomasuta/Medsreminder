import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MedicinesModule } from '../medicines/medicines.module.js';
import { PrescriptionsController } from './prescriptions.controller.js';
import { PrescriptionsService } from './prescriptions.service.js';
import { PrescriptionItem } from './schema/prescription-item.entity.js';
import { Prescription } from './schema/prescription.entity.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([Prescription, PrescriptionItem]),
    MedicinesModule,
  ],
  controllers: [PrescriptionsController],
  providers: [PrescriptionsService],
  exports: [TypeOrmModule],
})
export class PrescriptionsModule {}
