import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateScheduleRuleDto } from './dto/create-schedule-rule.dto.js';
import { ListScheduleRulesQueryDto } from './dto/list-schedule-rules.query.js';
import { UpdateScheduleRuleDto } from './dto/update-schedule-rule.dto.js';
import { ScheduleRulesService } from './schedule-rules.service.js';

@Controller('api/v1')
@ApiTags('Schedule rules')
export class ScheduleRulesController {
  constructor(private readonly scheduleRulesService: ScheduleRulesService) {}

  @Get('schedule-rules')
  @ApiOperation({ summary: 'List dose times for one patient so the phone can set alarms' })
  list(@Query() query: ListScheduleRulesQueryDto) {
    return this.scheduleRulesService.list(query);
  }

  @Get('schedule-rules/:id')
  @ApiOperation({ summary: 'Get one dose time with its medicine' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.scheduleRulesService.getById(id);
  }

  @Post('prescription-items/:id/schedules')
  @ApiOperation({ summary: 'Add one dose time to a medicine already on a prescription' })
  create(@Param('id', ParseUUIDPipe) id: string, @Body() dto: CreateScheduleRuleDto) {
    return this.scheduleRulesService.create(id, dto);
  }

  @Patch('schedule-rules/:id')
  @ApiOperation({ summary: 'Change or turn off one dose time' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateScheduleRuleDto) {
    return this.scheduleRulesService.update(id, dto);
  }
}
