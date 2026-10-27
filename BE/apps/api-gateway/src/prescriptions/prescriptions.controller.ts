import { BadRequestException, Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query, Req, Res, StreamableFile, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBadRequestResponse, ApiBody, ApiConsumes, ApiCookieAuth, ApiCreatedResponse, ApiForbiddenResponse, ApiNotFoundResponse, ApiOkResponse, ApiOperation, ApiParam, ApiResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import type { Response } from 'express';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import { Role, UserRole } from '../auth/guards/authorizedByRoles/roles.decorator.js';
import { RolesGuard } from '../auth/guards/authorizedByRoles/roles.guard.js';
import { CreatePrescriptionItemDto, CreatePrescriptionDto } from './dto/create-prescription.dto.js';
import { ScanPrescriptionDto } from './dto/scan-prescription.dto.js';
import { ListPrescriptionsQueryDto } from './dto/list-prescriptions.query.js';
import { PrescriptionItemResponseDto, PrescriptionResponseDto } from './dto/prescription-response.dto.js';
import { UpdatePrescriptionItemDto } from './dto/update-prescription-item.dto.js';
import { UpdatePrescriptionDto } from './dto/update-prescription.dto.js';
import { PrescriptionsService } from './prescriptions.service.js';

const writers = [UserRole.PATIENT, UserRole.CARE_GIVER, UserRole.ADMIN];

type AccessUser = {
  userId: string;
  role: string;
};
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
    description: 'Each line stores its own name, unit, and optional image. It does not reference the pharmacy catalog. Every line needs at least one reminder time. Omitted daysOfWeek means every day. A patient is stored as the owner from the access token. Premium accounts also receive an interaction check against the patient\'s other active medicines. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiCreatedResponse({ type: PrescriptionResponseDto, description: 'The prescription, its lines, and their dose times.' })
  @ApiBadRequestResponse({ description: 'A required field is missing, a date or time is invalid, or a line has no schedule.' })
  create(@Body() dto: CreatePrescriptionDto, @Req() request: Request) {
    return this.prescriptionsService.create(dto, this.user(request));
  }

  @Post('prescriptions/scan')
  @Role(...writers)
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['image', 'patientId'],
      properties: {
        image: { type: 'string', format: 'binary', description: 'JPEG, PNG, or WebP photo from a file picker or camera' },
        patientId: { type: 'string' },
        createdByCgId: { type: 'string' },
        startDate: { type: 'string', example: '2026-10-15' },
        endDate: { type: 'string', example: '2026-11-15' },
      },
    },
  })
  @ApiOperation({
    summary: 'Read a prescription photo and return a draft',
    description: 'Premium accounts only. Accepts a JPEG, PNG, or WebP file. The model reads the photo and returns the draft. Nothing is saved until the client confirms with POST /prescriptions. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiOkResponse({ type: PrescriptionResponseDto, description: 'The unsaved draft read from the photo.' })
  @ApiBadRequestResponse({ description: 'The photo is missing or not JPEG, PNG, or WebP, or the model could not read a medicine line.' })
  @ApiForbiddenResponse({ description: 'The account is not premium.' })
  scan(
    @UploadedFile() file: { buffer?: Buffer; mimetype?: string; size?: number } | undefined,
    @Body() dto: ScanPrescriptionDto,
    @Req() request: Request,
  ) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Hãy chọn ảnh đơn thuốc');
    }
    return this.prescriptionsService.scan(dto, file.buffer, file.mimetype ?? '', this.user(request));
  }

  @Get('prescriptions')
  @Role(...readers)
  @ApiOperation({
    summary: 'List prescriptions for one patient test CD',
    description: 'A patient always receives their own prescriptions. The patientId query is ignored for that role. Pharmacists can read a prescription while reviewing an order. Allowed roles: PATIENT, CARE_GIVER, PHARMACIST, ADMIN.',
  })
  @ApiOkResponse({ type: PrescriptionResponseDto, isArray: true, description: 'Prescriptions for the patient, newest first.' })
  @ApiBadRequestResponse({ description: 'patientId is missing or is not an ObjectId.' })
  list(@Query() query: ListPrescriptionsQueryDto, @Req() request: Request) {
    return this.prescriptionsService.list(query, this.user(request));
  }

  @Get('prescriptions/:id')
  @Role(...readers)
  @ApiOperation({
    summary: 'Get one prescription with its medicine lines and dose times',
    description: 'A patient can open only a prescription whose patient id matches the access token. Allowed roles: PATIENT, CARE_GIVER, PHARMACIST, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: PrescriptionResponseDto })
  @ApiBadRequestResponse({ description: 'id is not a UUID.' })
  @ApiNotFoundResponse({ description: 'Prescription not found.' })
  getById(@Param('id', ParseUUIDPipe) id: string, @Req() request: Request) {
    return this.prescriptionsService.getById(id, this.user(request));
  }

  @Get('prescriptions/:id/photo')
  @Role(...readers)
  @ApiOperation({ summary: 'Download the prescription photo stored from a scan' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ description: 'The stored JPEG, PNG, or WebP bytes.' })
  @ApiNotFoundResponse({ description: 'Prescription or photo not found.' })
  async photo(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() request: Request,
    @Res({ passthrough: true }) response: Response,
  ) {
    const photo = await this.prescriptionsService.photo(id, this.user(request));
    const contentType = photo.contentType === 'image/jpeg'
      || photo.contentType === 'image/png'
      || photo.contentType === 'image/webp'
      ? photo.contentType
      : 'application/octet-stream';
    response.setHeader('Content-Type', contentType);
    response.setHeader('X-Content-Type-Options', 'nosniff');
    response.setHeader('Cache-Control', 'private, no-store');
    return new StreamableFile(Buffer.from(photo.imageBase64, 'base64'));
  }

  @Patch('prescriptions/:id')
  @Role(...writers)
  @ApiOperation({
    summary: 'Update prescription document fields',
    description: 'Changes title, doctor, code, dates, photo URL, or active flag. Medicine lines and dose times are updated on their own routes. A patient can update only their own prescription. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: PrescriptionResponseDto, description: 'The prescription after the document fields were saved.' })
  @ApiBadRequestResponse({ description: 'No field was sent, or a date is invalid.' })
  @ApiNotFoundResponse({ description: 'Prescription not found.' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePrescriptionDto, @Req() request: Request) {
    return this.prescriptionsService.update(id, dto, this.user(request));
  }

  @Post('prescriptions/:id/items')
  @Role(...writers)
  @ApiOperation({
    summary: 'Add one medicine line and its dose times to a prescription',
    description: 'The line carries the medicine name, unit, dose, and home stock. It needs at least one reminder time. A patient can add a line only to their own prescription. Premium accounts also receive an interaction check against the patient\'s other active medicines. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Prescription id' })
  @ApiCreatedResponse({ type: PrescriptionItemResponseDto, description: 'The new medicine line and its dose times.' })
  @ApiBadRequestResponse({ description: 'The line has no name, an invalid unit, or no schedule.' })
  @ApiNotFoundResponse({ description: 'Prescription not found.' })
  addItem(@Param('id', ParseUUIDPipe) id: string, @Body() dto: CreatePrescriptionItemDto, @Req() request: Request) {
    return this.prescriptionsService.addItem(id, dto, this.user(request));
  }

  @Patch('prescription-items/:id')
  @Role(...writers)
  @ApiOperation({
    summary: 'Update one medicine line',
    description: 'Changes the name, unit, image, dose, home stock, reorder threshold, or instructions of a single line. Dose times stay on the schedule routes. A patient can update only a line on their own prescription. Changing the medicine name runs the premium interaction check. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Prescription item id' })
  @ApiOkResponse({ type: PrescriptionItemResponseDto, description: 'The medicine line after the update.' })
  @ApiBadRequestResponse({ description: 'No field was sent, or a field is invalid.' })
  @ApiNotFoundResponse({ description: 'Prescription item not found.' })
  updateItem(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePrescriptionItemDto, @Req() request: Request) {
    return this.prescriptionsService.updateItem(id, dto, this.user(request));
  }

  private user(request: Request) {
    return (request as Request & { user: AccessUser }).user;
  }
}
