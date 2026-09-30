import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PrescriptionItem } from '../prescriptions/schema/prescription-item.entity.js';
import { ScheduleRulesController } from './schedule-rules.controller.js';
import { ScheduleRulesService } from './schedule-rules.service.js';
import { ScheduleRule } from './schema/schedule-rule.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([ScheduleRule, PrescriptionItem])],
  controllers: [ScheduleRulesController],
  providers: [ScheduleRulesService],
  exports: [TypeOrmModule],
})
export class ScheduleRulesModule {}
