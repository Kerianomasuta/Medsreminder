import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Post, Query, Req, Res, StreamableFile, UseGuards } from '@nestjs/common';
import { ApiBadRequestResponse, ApiCookieAuth, ApiForbiddenResponse, ApiNotFoundResponse, ApiOkResponse, ApiOperation, ApiParam, ApiProduces, ApiResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import { Role, UserRole } from '../auth/guards/authorizedByRoles/roles.decorator.js';
import { RolesGuard } from '../auth/guards/authorizedByRoles/roles.guard.js';
import { ComplianceReportQueryDto, ListMedicationLogsQueryDto, MedicationLogResponseDto, RecordDoseDto, SkipDoseDto, SnoozeDoseDto } from './dto/medication-log.dto.js';
import { MedicationLogsService } from './medication-logs.service.js';

type AccessUser = {
  userId: string;
  role: string;
  fullName?: string;
};

const openDose = 'The dose must still be SCHEDULED or SNOOZED. TAKEN, SKIPPED, and MISSED cannot be changed.';

@Controller('api/v1/medication-logs')
@ApiTags('Medication logs')
@ApiCookieAuth('accessToken')
@UseGuards(JwtAuthGuard, RolesGuard)
@Role(UserRole.PATIENT)
@ApiUnauthorizedResponse({ description: 'Access token cookie is missing or expired.' })
@ApiForbiddenResponse({ description: 'The signed-in role cannot call this route.' })
@ApiResponse({ status: 503, description: 'Medication service is unavailable.' })
export class MedicationLogsController {
  constructor(private readonly medicationLogsService: MedicationLogsService) {}

  @Get('compliance-report')
  @Role(UserRole.PATIENT, UserRole.CARE_GIVER, UserRole.ADMIN)
  @ApiProduces('application/pdf')
  @ApiOperation({
    summary: 'Download a 30-day compliance report as a PDF',
    description: 'Premium accounts only, except ADMIN. Covers the last 30 days in Asia/Ho_Chi_Minh: on-time rate, missed doses, and active prescriptions. A dose is on time when it was taken within 30 minutes of the reminder. PATIENT uses the access token. CARE_GIVER and ADMIN send patientId. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiOkResponse({
    description: 'The PDF file.',
    content: { 'application/pdf': { schema: { type: 'string', format: 'binary' } } },
  })
  @ApiBadRequestResponse({ description: 'CARE_GIVER or ADMIN did not provide a patientId ObjectId.' })
  @ApiForbiddenResponse({ description: 'The account is not premium.' })
  async complianceReport(
    @Query() query: ComplianceReportQueryDto,
    @Req() request: Request,
    @Res({ passthrough: true }) response: Response,
  ) {
    const report = await this.medicationLogsService.complianceReport(query, this.user(request));
    const filename = /^[a-z0-9.-]+$/.test(report.filename) ? report.filename : 'bao-cao-tuan-thu.pdf';
    response.setHeader('Content-Type', 'application/pdf');
    response.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    response.setHeader('Cache-Control', 'private, no-store');
    return new StreamableFile(Buffer.from(report.pdfBase64, 'base64'));
  }

  @Get()
  @Role(UserRole.PATIENT, UserRole.CARE_GIVER)
  @ApiOperation({
    summary: 'List the signed-in patient\'s doses from today onward',
    description: 'PATIENT uses the patient id from the access token. CARE_GIVER sends patientId. from defaults to today in Asia/Ho_Chi_Minh. to is an inclusive last day; omit it to include every later dose. Each row is one reminder instant and its current status. Allowed roles: PATIENT, CARE_GIVER.',
  })
  @ApiOkResponse({ type: MedicationLogResponseDto, isArray: true, description: 'Doses ordered by scheduled time.' })
  @ApiBadRequestResponse({ description: 'CARE_GIVER did not provide patientId; from or to is not a real YYYY-MM-DD date; or to is before from.' })
  list(@Query() query: ListMedicationLogsQueryDto, @Req() request: Request) {
    return this.medicationLogsService.list(query, this.user(request));
  }

  @Post(':id/taken')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Mark a dose as taken',
    description: `${openDose} Sets status to TAKEN and actualTakenAt to the server time. Clears snoozeUntil and skipReason. escalationLevel stays unchanged. Allowed role: PATIENT.`,
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Medication log id' })
  @ApiOkResponse({ type: MedicationLogResponseDto })
  @ApiBadRequestResponse({ description: 'The dose is already final.' })
  @ApiNotFoundResponse({ description: 'Dose log not found.' })
  take(@Param('id', ParseUUIDPipe) id: string, @Req() request: Request) {
    return this.medicationLogsService.take(id, this.user(request));
  }

  @Post(':id/snooze')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Snooze a dose for 5 or 10 minutes',
    description: `${openDose} Sets status to SNOOZED and snoozeUntil to the server time plus minutes. Does not raise escalationLevel. The phone sets the next alarm from snoozeUntil. Allowed role: PATIENT.`,
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Medication log id' })
  @ApiOkResponse({ type: MedicationLogResponseDto })
  @ApiBadRequestResponse({ description: 'minutes is not 5 or 10, or the dose is already final.' })
  @ApiNotFoundResponse({ description: 'Dose log not found.' })
  snooze(@Param('id', ParseUUIDPipe) id: string, @Body() dto: SnoozeDoseDto, @Req() request: Request) {
    return this.medicationLogsService.snooze(id, dto ?? {}, this.user(request));
  }

  @Post(':id/skip')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Skip a dose on purpose',
    description: `${openDose} Sets status to SKIPPED, stores skipReason when one was sent, and sets escalationLevel to 1. Clears snoozeUntil. Allowed role: PATIENT.`,
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Medication log id' })
  @ApiOkResponse({ type: MedicationLogResponseDto })
  @ApiBadRequestResponse({ description: 'The dose is already final, or skipReason is too long.' })
  @ApiNotFoundResponse({ description: 'Dose log not found.' })
  skip(@Param('id', ParseUUIDPipe) id: string, @Body() dto: SkipDoseDto, @Req() request: Request) {
    return this.medicationLogsService.skip(id, dto ?? {}, this.user(request));
  }

  @Post(':id/missed')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Mark a dose missed after two 3-minute alarms',
    description: `${openDose} The phone rings for 3 minutes, waits 5 minutes, then rings again for 3 minutes. It calls this endpoint when the second alarm ends. For SCHEDULED, the server time must be at least 11 minutes after scheduledAt. For SNOOZED, it must be at least 11 minutes after snoozeUntil. Sets status to MISSED and escalationLevel to 1. Allowed role: PATIENT.`,
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Medication log id' })
  @ApiOkResponse({ type: MedicationLogResponseDto })
  @ApiBadRequestResponse({ description: '11 minutes have not passed since the current reminder, or the dose is already final.' })
  @ApiNotFoundResponse({ description: 'Dose log not found.' })
  miss(@Param('id', ParseUUIDPipe) id: string, @Body() dto: RecordDoseDto, @Req() request: Request) {
    return this.medicationLogsService.miss(id, dto ?? {}, this.user(request));
  }

  private user(request: Request) {
    return (request as Request & { user: AccessUser }).user;
  }
}
