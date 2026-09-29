import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MedicationLog } from './schema/medication-log.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([MedicationLog])],
  exports: [TypeOrmModule],
})
export class MedicationLogsModule {}
