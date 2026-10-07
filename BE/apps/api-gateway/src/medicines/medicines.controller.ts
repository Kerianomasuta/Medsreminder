import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBadRequestResponse, ApiConflictResponse, ApiCookieAuth, ApiCreatedResponse, ApiForbiddenResponse, ApiNotFoundResponse, ApiOkResponse, ApiOperation, ApiParam, ApiResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import { Role, UserRole } from '../auth/guards/authorizedByRoles/roles.decorator.js';
import { RolesGuard } from '../auth/guards/authorizedByRoles/roles.guard.js';
import { CreateMedicineDto } from './dto/create-medicine.dto.js';
import { ListMedicinesQueryDto } from './dto/list-medicines.query.js';
import { MedicineResponseDto } from './dto/medicine-response.dto.js';
import { UpdateMedicineDto } from './dto/update-medicine.dto.js';
import { MedicinesService } from './medicines.service.js';

const catalogWriters = [UserRole.PHARMACIST, UserRole.ADMIN];
const catalogReaders = [UserRole.PHARMACIST, UserRole.CARE_GIVER, UserRole.ADMIN];

@Controller('api/v1/medicines')
@ApiTags('Medicines')
@ApiCookieAuth('accessToken')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiUnauthorizedResponse({ description: 'Access token cookie is missing or expired.' })
@ApiForbiddenResponse({ description: 'The signed-in role cannot call this route.' })
@ApiResponse({ status: 503, description: 'Medication service is unavailable.' })
export class MedicinesController {
  constructor(private readonly medicinesService: MedicinesService) {}

  @Post()
  @Role(...catalogWriters)
  @ApiOperation({
    summary: 'Add a medicine identity for pharmacy inventory',
    description: 'Creates a row in the shared pharmacy catalog. Prescriptions do not use this id. The same name and unit cannot be created twice. Allowed roles: PHARMACIST, ADMIN.',
  })
  @ApiCreatedResponse({ type: MedicineResponseDto, description: 'The medicine identity was created.' })
  @ApiBadRequestResponse({ description: 'Name or unit is missing or invalid. Unit must be VIEN, GOI, or CHAI.' })
  @ApiConflictResponse({ description: 'A medicine with this name and unit already exists.' })
  create(@Body() dto: CreateMedicineDto) {
    return this.medicinesService.create(dto);
  }

  @Get()
  @Role(...catalogReaders)
  @ApiOperation({
    summary: 'List pharmacy medicine identities',
    description: 'Caregivers use this list when choosing a pharmacy product for an order. Search matches name or generic name. Allowed roles: PHARMACIST, CARE_GIVER, ADMIN.',
  })
  @ApiOkResponse({ type: MedicineResponseDto, isArray: true, description: 'Matching medicine identities, ordered by name.' })
  @ApiBadRequestResponse({ description: 'The search query is invalid.' })
  list(@Query() query: ListMedicinesQueryDto) {
    return this.medicinesService.list(query.search);
  }

  @Get(':id')
  @Role(...catalogReaders)
  @ApiOperation({
    summary: 'Get one pharmacy medicine identity',
    description: 'Allowed roles: PHARMACIST, CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: MedicineResponseDto, description: 'The medicine identity.' })
  @ApiBadRequestResponse({ description: 'id is not a UUID.' })
  @ApiNotFoundResponse({ description: 'Medicine not found.' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.medicinesService.getById(id);
  }

  @Patch(':id')
  @Role(...catalogWriters)
  @ApiOperation({
    summary: 'Update a pharmacy medicine identity',
    description: 'Send at least one field. Renaming or changing the unit is rejected when another identity already uses that name and unit. Allowed roles: PHARMACIST, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: MedicineResponseDto, description: 'The updated medicine identity.' })
  @ApiBadRequestResponse({ description: 'No field was sent, or a field is invalid.' })
  @ApiNotFoundResponse({ description: 'Medicine not found.' })
  @ApiConflictResponse({ description: 'A medicine with this name and unit already exists.' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateMedicineDto) {
    return this.medicinesService.update(id, dto);
  }
}
