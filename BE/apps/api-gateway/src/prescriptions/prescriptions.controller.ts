import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBadRequestResponse, ApiCookieAuth, ApiCreatedResponse, ApiForbiddenResponse, ApiNotFoundResponse, ApiOkResponse, ApiOperation, ApiParam, ApiResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import { Role, UserRole } from '../auth/guards/authorizedByRoles/roles.decorator.js';
import { RolesGuard } from '../auth/guards/authorizedByRoles/roles.guard.js';
import { CreatePrescriptionItemDto, CreatePrescriptionDto } from './dto/create-prescription.dto.js';
import { ListPrescriptionsQueryDto } from './dto/list-prescriptions.query.js';
import { PrescriptionItemResponseDto, PrescriptionResponseDto } from './dto/prescription-response.dto.js';
import { UpdatePrescriptionItemDto } from './dto/update-prescription-item.dto.js';
import { UpdatePrescriptionDto } from './dto/update-prescription.dto.js';
import { PrescriptionsService } from './prescriptions.service.js';

const writers = [UserRole.CARE_GIVER, UserRole.ADMIN];
const readers = [UserRole.PATIENT, UserRole.CARE_GIVER, UserRole.PHARMACIST, UserRole.ADMIN];

@Controller('api/v1')
@ApiTags('Prescriptions')
@ApiCookieAuth('accessToken')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiUnauthorizedResponse({ description: 'Access token cookie is missing or expired.' })
@ApiForbiddenResponse({ description: 'The signed-in role cannot call this route.' })
@ApiResponse({ status: 503, description: 'Medication service is unavailable.' })
export class PrescriptionsController {
  constructor(private readonly prescriptionsService: PrescriptionsService) {}

  @Post('prescriptions')
  @Role(...writers)
  @ApiOperation({
    summary: 'Create a prescription with its medicine lines and dose times',
    description: 'Each line stores its own name, unit, and optional image. It does not reference the pharmacy catalog. Every line needs at least one reminder time. Omitted daysOfWeek means every day. Allowed roles: CARE_GIVER, ADMIN.',
  })
  @ApiCreatedResponse({ type: PrescriptionResponseDto, description: 'The prescription, its lines, and their dose times.' })
  @ApiBadRequestResponse({ description: 'A required field is missing, a date or time is invalid, or a line has no schedule.' })
  create(@Body() dto: CreatePrescriptionDto) {
    return this.prescriptionsService.create(dto);
  }

  @Get('prescriptions')
  @Role(...readers)
  @ApiOperation({
    summary: 'List prescriptions for one patient',
    description: 'Pharmacists can read a prescription while reviewing an order. The response includes medicine lines and dose times. Allowed roles: PATIENT, CARE_GIVER, PHARMACIST, ADMIN.',
  })
  @ApiOkResponse({ type: PrescriptionResponseDto, isArray: true, description: 'Prescriptions for the patient, newest first.' })
  @ApiBadRequestResponse({ description: 'patientId is missing or is not an ObjectId.' })
  list(@Query() query: ListPrescriptionsQueryDto) {
    return this.prescriptionsService.list(query);
  }

  @Get('prescriptions/:id')
  @Role(...readers)
  @ApiOperation({
    summary: 'Get one prescription with its medicine lines and dose times',
    description: 'Allowed roles: PATIENT, CARE_GIVER, PHARMACIST, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: PrescriptionResponseDto })
  @ApiBadRequestResponse({ description: 'id is not a UUID.' })
  @ApiNotFoundResponse({ description: 'Prescription not found.' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.prescriptionsService.getById(id);
  }

  @Patch('prescriptions/:id')
  @Role(...writers)
  @ApiOperation({
    summary: 'Update prescription document fields',
    description: 'Changes title, doctor, code, dates, photo URL, or active flag. Medicine lines and dose times are updated on their own routes. Allowed roles: CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: PrescriptionResponseDto, description: 'The prescription after the document fields were saved.' })
  @ApiBadRequestResponse({ description: 'No field was sent, or a date is invalid.' })
  @ApiNotFoundResponse({ description: 'Prescription not found.' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePrescriptionDto) {
    return this.prescriptionsService.update(id, dto);
  }

  @Post('prescriptions/:id/items')
  @Role(...writers)
  @ApiOperation({
    summary: 'Add one medicine line and its dose times to a prescription',
    description: 'The line carries the medicine name, unit, dose, and home stock. It needs at least one reminder time. Allowed roles: CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Prescription id' })
  @ApiCreatedResponse({ type: PrescriptionItemResponseDto, description: 'The new medicine line and its dose times.' })
  @ApiBadRequestResponse({ description: 'The line has no name, an invalid unit, or no schedule.' })
  @ApiNotFoundResponse({ description: 'Prescription not found.' })
  addItem(@Param('id', ParseUUIDPipe) id: string, @Body() dto: CreatePrescriptionItemDto) {
    return this.prescriptionsService.addItem(id, dto);
  }

  @Patch('prescription-items/:id')
  @Role(...writers)
  @ApiOperation({
    summary: 'Update one medicine line',
    description: 'Changes the name, unit, image, dose, home stock, reorder threshold, or instructions of a single line. Dose times stay on the schedule routes. Allowed roles: CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Prescription item id' })
  @ApiOkResponse({ type: PrescriptionItemResponseDto, description: 'The medicine line after the update.' })
  @ApiBadRequestResponse({ description: 'No field was sent, or a field is invalid.' })
  @ApiNotFoundResponse({ description: 'Prescription item not found.' })
  updateItem(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePrescriptionItemDto) {
    return this.prescriptionsService.updateItem(id, dto);
  }
}
