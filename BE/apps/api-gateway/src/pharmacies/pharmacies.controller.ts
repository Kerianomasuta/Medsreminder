<<<<<<< HEAD
import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreatePharmacyDto } from './dto/create-pharmacy.dto.js';
import { ListPharmaciesQueryDto } from './dto/list-pharmacies.query.js';
import { UpdatePharmacyDto } from './dto/update-pharmacy.dto.js';
import { UpsertInventoryDto } from './dto/upsert-inventory.dto.js';
import { PharmaciesService } from './pharmacies.service.js';

@Controller('api/v1/pharmacies')
=======
import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateInventoryDto, UpdateInventoryDto } from './dto/create-inventory.dto.js';
import { CreatePharmacyDto, UpdatePharmacyDto } from './dto/create-pharmacy.dto.js';
import { ListPharmaciesQueryDto } from './dto/list-pharmacies.query.js';
import { PharmaciesService } from './pharmacies.service.js';

@Controller('api/v1')
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
@ApiTags('Pharmacies')
export class PharmaciesController {
  constructor(private readonly pharmaciesService: PharmaciesService) {}

<<<<<<< HEAD
  @Post()
=======
  @Post('pharmacies')
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  @ApiOperation({ summary: 'Register a pharmacy' })
  create(@Body() dto: CreatePharmacyDto) {
    return this.pharmaciesService.create(dto);
  }

<<<<<<< HEAD
  @Get()
  @ApiOperation({ summary: 'List pharmacies, nearest first when coordinates are sent' })
=======
  @Get('pharmacies')
  @ApiOperation({ summary: 'List pharmacies, optionally filtered by name' })
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  list(@Query() query: ListPharmaciesQueryDto) {
    return this.pharmaciesService.list(query);
  }

<<<<<<< HEAD
  @Get(':id')
=======
  @Get('pharmacies/:id')
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  @ApiOperation({ summary: 'Get one pharmacy' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.pharmaciesService.getById(id);
  }

<<<<<<< HEAD
  @Patch(':id')
  @ApiOperation({ summary: 'Update pharmacy details' })
=======
  @Patch('pharmacies/:id')
  @ApiOperation({ summary: 'Update a pharmacy' })
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePharmacyDto) {
    return this.pharmaciesService.update(id, dto);
  }

<<<<<<< HEAD
  @Get(':id/inventory')
=======
  @Get('pharmacies/:id/inventory')
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  @ApiOperation({ summary: 'List stock and prices at one pharmacy' })
  listInventory(@Param('id', ParseUUIDPipe) id: string) {
    return this.pharmaciesService.listInventory(id);
  }

<<<<<<< HEAD
  @Put(':id/inventory')
  @ApiOperation({ summary: 'Set stock and price for one medicine' })
  upsertInventory(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpsertInventoryDto) {
    return this.pharmaciesService.upsertInventory(id, dto);
=======
  @Post('pharmacies/:id/inventory')
  @ApiOperation({ summary: 'Add a catalog medicine to a pharmacy' })
  addInventory(@Param('id', ParseUUIDPipe) id: string, @Body() dto: CreateInventoryDto) {
    return this.pharmaciesService.addInventory(id, dto);
  }

  @Patch('pharmacy-inventory/:id')
  @ApiOperation({ summary: 'Update stock or price of one inventory row' })
  updateInventory(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateInventoryDto) {
    return this.pharmaciesService.updateInventory(id, dto);
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  }
}
