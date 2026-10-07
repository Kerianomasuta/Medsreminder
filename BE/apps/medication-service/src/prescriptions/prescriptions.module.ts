import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PrescriptionsController } from './prescriptions.controller.js';
import { PrescriptionsService } from './prescriptions.service.js';
import { PrescriptionItem } from './schema/prescription-item.entity.js';
import { Prescription } from './schema/prescription.entity.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([Prescription, PrescriptionItem]),
  ],
  controllers: [PrescriptionsController],
  providers: [PrescriptionsService],
  exports: [TypeOrmModule],
})
export class PrescriptionsModule {}
