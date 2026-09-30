import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleRule } from './schema/schedule-rule.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([ScheduleRule])],
  exports: [TypeOrmModule],
})
export class ScheduleRulesModule {}
