import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateMedicineDto } from './dto/create-medicine.dto.js';
import { ListMedicinesQueryDto } from './dto/list-medicines.query.js';
import { UpdateMedicineDto } from './dto/update-medicine.dto.js';
import { MedicinesService } from './medicines.service.js';

@Controller('api/v1/medicines')
@ApiTags('Medicines')
export class MedicinesController {
  constructor(private readonly medicinesService: MedicinesService) {}

  @Post()
  @ApiOperation({ summary: 'Add a medicine to the shared catalog' })
  create(@Body() dto: CreateMedicineDto) {
    return this.medicinesService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List medicines, optionally filtered by name' })
  list(@Query() query: ListMedicinesQueryDto) {
    return this.medicinesService.list(query.search);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one medicine' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.medicinesService.getById(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a medicine in the catalog' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateMedicineDto) {
    return this.medicinesService.update(id, dto);
  }
}
