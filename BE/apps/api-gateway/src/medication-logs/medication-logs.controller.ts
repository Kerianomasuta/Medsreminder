import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBadRequestResponse, ApiCookieAuth, ApiForbiddenResponse, ApiNotFoundResponse, ApiOkResponse, ApiOperation, ApiParam, ApiResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import { Role, UserRole } from '../auth/guards/authorizedByRoles/roles.decorator.js';
import { RolesGuard } from '../auth/guards/authorizedByRoles/roles.guard.js';
import { ListMedicationLogsQueryDto, MedicationLogResponseDto, RecordDoseDto, SkipDoseDto, SnoozeDoseDto } from './dto/medication-log.dto.js';
import { MedicationLogsService } from './medication-logs.service.js';

type AccessUser = {
  userId: string;
  role: string;
};

const openDose = 'The dose must still be SCHEDULED or SNOOZED. TAKEN, SKIPPED, and MISSED cannot be changed.';

@Controller('api/v1/medication-logs')
@ApiTags('Medication logs')
@ApiCookieAuth('accessToken')
@UseGuards(JwtAuthGuard, RolesGuard)
@Role(UserRole.PATIENT)
@ApiUnauthorizedResponse({ description: 'Access token cookie is missing or expired.' })
@ApiForbiddenResponse({ description: 'The signed-in user is not the patient for this dose. Allowed role: PATIENT.' })
@ApiResponse({ status: 503, description: 'Medication service is unavailable.' })
export class MedicationLogsController {
  constructor(private readonly medicationLogsService: MedicationLogsService) {}

  @Get()
  @ApiOperation({
    summary: 'List the signed-in patient\'s doses from today onward',
    description: 'The patient id comes from the access token. from defaults to today in Asia/Ho_Chi_Minh. to is an inclusive last day; omit it to include every later dose. Each row is one reminder instant and its current status. Allowed role: PATIENT.',
  })
  @ApiOkResponse({ type: MedicationLogResponseDto, isArray: true, description: 'Doses ordered by scheduled time.' })
  @ApiBadRequestResponse({ description: 'from or to is not a real YYYY-MM-DD date, or to is before from.' })
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
    summary: 'Mark a dose missed after two 10-minute alarms',
    description: `${openDose} The phone rings for 10 minutes, then rings again for 10 minutes. It calls this endpoint when the second alarm ends. For SCHEDULED, the server time must be at least 20 minutes after scheduledAt. For SNOOZED, it must be at least 20 minutes after snoozeUntil. Sets status to MISSED and escalationLevel to 1. Allowed role: PATIENT.`,
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Medication log id' })
  @ApiOkResponse({ type: MedicationLogResponseDto })
  @ApiBadRequestResponse({ description: '20 minutes have not passed since the current reminder, or the dose is already final.' })
  @ApiNotFoundResponse({ description: 'Dose log not found.' })
  miss(@Param('id', ParseUUIDPipe) id: string, @Body() dto: RecordDoseDto, @Req() request: Request) {
    return this.medicationLogsService.miss(id, dto ?? {}, this.user(request));
  }

  private user(request: Request) {
    return (request as Request & { user: AccessUser }).user;
  }
}
