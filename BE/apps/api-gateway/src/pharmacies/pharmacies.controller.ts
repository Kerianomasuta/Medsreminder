import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreatePharmacyDto } from './dto/create-pharmacy.dto.js';
import { ListPharmaciesQueryDto } from './dto/list-pharmacies.query.js';
import { UpdatePharmacyDto } from './dto/update-pharmacy.dto.js';
import { UpsertInventoryDto } from './dto/upsert-inventory.dto.js';
import { PharmaciesService } from './pharmacies.service.js';

@Controller('api/v1/pharmacies')
@ApiTags('Pharmacies')
export class PharmaciesController {
  constructor(private readonly pharmaciesService: PharmaciesService) {}

  @Post()
  @ApiOperation({ summary: 'Register a pharmacy' })
  create(@Body() dto: CreatePharmacyDto) {
    return this.pharmaciesService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List pharmacies, nearest first when coordinates are sent' })
  list(@Query() query: ListPharmaciesQueryDto) {
    return this.pharmaciesService.list(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one pharmacy' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.pharmaciesService.getById(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update pharmacy details' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePharmacyDto) {
    return this.pharmaciesService.update(id, dto);
  }

  @Get(':id/inventory')
  @ApiOperation({ summary: 'List stock and prices at one pharmacy' })
  listInventory(@Param('id', ParseUUIDPipe) id: string) {
    return this.pharmaciesService.listInventory(id);
  }

  @Put(':id/inventory')
  @ApiOperation({ summary: 'Set stock and price for many medicines at once' })
  upsertInventory(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpsertInventoryDto) {
    return this.pharmaciesService.upsertInventory(id, dto);
  }
}
