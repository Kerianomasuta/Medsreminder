import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MedicationLog } from '../medication-logs/schema/medication-log.entity.js';
import { PrescriptionItem } from '../prescriptions/schema/prescription-item.entity.js';
import { Prescription } from '../prescriptions/schema/prescription.entity.js';
import { ScheduleRule } from '../schedule-rules/schema/schedule-rule.entity.js';
import { AdminMedicationController } from './admin-medication.controller.js';
import { AdminMedicationService } from './admin-medication.service.js';

@Module({
  imports: [TypeOrmModule.forFeature([Prescription, PrescriptionItem, ScheduleRule, MedicationLog])],
  controllers: [AdminMedicationController],
  providers: [AdminMedicationService],
})
export class AdminMedicationModule {}
