import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { ListPharmaciesQueryDto } from './dto/list-pharmacies.query.js';
import { PharmaciesService } from './pharmacies.service.js';

@Controller('api/v1/pharmacies')
@ApiTags('Pharmacies')
export class PharmaciesController {
  constructor(private readonly pharmaciesService: PharmaciesService) {}

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
}
