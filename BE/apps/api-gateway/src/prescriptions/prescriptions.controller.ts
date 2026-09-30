import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreatePrescriptionItemDto, CreatePrescriptionDto } from './dto/create-prescription.dto.js';
import { ListPrescriptionsQueryDto } from './dto/list-prescriptions.query.js';
import { UpdatePrescriptionItemDto } from './dto/update-prescription-item.dto.js';
import { UpdatePrescriptionDto } from './dto/update-prescription.dto.js';
import { UpdateScheduleRuleDto } from './dto/update-schedule-rule.dto.js';
import { PrescriptionsService } from './prescriptions.service.js';

@Controller('api/v1')
@ApiTags('Prescriptions')
export class PrescriptionsController {
  constructor(private readonly prescriptionsService: PrescriptionsService) {}

  @Post('prescriptions')
  @ApiOperation({ summary: 'Create a prescription with medicines and dose times' })
  create(@Body() dto: CreatePrescriptionDto) {
    return this.prescriptionsService.create(dto);
  }

  @Get('prescriptions')
  @ApiOperation({ summary: 'List prescriptions for one patient' })
  list(@Query() query: ListPrescriptionsQueryDto) {
    return this.prescriptionsService.list(query);
  }

  @Get('prescriptions/:id')
  @ApiOperation({ summary: 'Get one prescription with medicines and schedules' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.prescriptionsService.getById(id);
  }

  @Patch('prescriptions/:id')
  @ApiOperation({ summary: 'Update prescription details' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePrescriptionDto) {
    return this.prescriptionsService.update(id, dto);
  }

  @Post('prescriptions/:id/items')
  @ApiOperation({ summary: 'Add one medicine and its dose times to a prescription' })
  addItem(@Param('id', ParseUUIDPipe) id: string, @Body() dto: CreatePrescriptionItemDto) {
    return this.prescriptionsService.addItem(id, dto);
  }

  @Patch('prescription-items/:id')
  @ApiOperation({ summary: 'Update dose, stock, or instructions of one medicine line' })
  updateItem(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePrescriptionItemDto) {
    return this.prescriptionsService.updateItem(id, dto);
  }

  @Patch('schedule-rules/:id')
  @ApiOperation({ summary: 'Update one dose time' })
  updateSchedule(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateScheduleRuleDto) {
    return this.prescriptionsService.updateSchedule(id, dto);
  }
}
