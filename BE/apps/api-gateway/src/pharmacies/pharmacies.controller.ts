import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateInventoryDto, UpdateInventoryDto } from './dto/create-inventory.dto.js';
import { CreatePharmacyDto, UpdatePharmacyDto } from './dto/create-pharmacy.dto.js';
import { ListPharmaciesQueryDto } from './dto/list-pharmacies.query.js';
import { PharmaciesService } from './pharmacies.service.js';

@Controller('api/v1')
@ApiTags('Pharmacies')
export class PharmaciesController {
  constructor(private readonly pharmaciesService: PharmaciesService) {}

  @Post('pharmacies')
  @ApiOperation({ summary: 'Register a pharmacy' })
  create(@Body() dto: CreatePharmacyDto) {
    return this.pharmaciesService.create(dto);
  }

  @Get('pharmacies')
  @ApiOperation({ summary: 'List pharmacies, optionally filtered by name' })
  list(@Query() query: ListPharmaciesQueryDto) {
    return this.pharmaciesService.list(query);
  }

  @Get('pharmacies/:id')
  @ApiOperation({ summary: 'Get one pharmacy' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.pharmaciesService.getById(id);
  }

  @Patch('pharmacies/:id')
  @ApiOperation({ summary: 'Update a pharmacy' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePharmacyDto) {
    return this.pharmaciesService.update(id, dto);
  }

  @Get('pharmacies/:id/inventory')
  @ApiOperation({ summary: 'List stock and prices at one pharmacy' })
  listInventory(@Param('id', ParseUUIDPipe) id: string) {
    return this.pharmaciesService.listInventory(id);
  }

  @Post('pharmacies/:id/inventory')
  @ApiOperation({ summary: 'Add a catalog medicine to a pharmacy' })
  addInventory(@Param('id', ParseUUIDPipe) id: string, @Body() dto: CreateInventoryDto) {
    return this.pharmaciesService.addInventory(id, dto);
  }

  @Patch('pharmacy-inventory/:id')
  @ApiOperation({ summary: 'Update stock or price of one inventory row' })
  updateInventory(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateInventoryDto) {
    return this.pharmaciesService.updateInventory(id, dto);
  }
}
