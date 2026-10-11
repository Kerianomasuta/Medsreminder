import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBadRequestResponse, ApiCookieAuth, ApiCreatedResponse, ApiForbiddenResponse, ApiNotFoundResponse, ApiOkResponse, ApiOperation, ApiParam, ApiResponse, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import { Role, UserRole } from '../auth/guards/authorizedByRoles/roles.decorator.js';
import { RolesGuard } from '../auth/guards/authorizedByRoles/roles.guard.js';
import { CreateScheduleRuleDto } from './dto/create-schedule-rule.dto.js';
import { ListScheduleRulesQueryDto } from './dto/list-schedule-rules.query.js';
import { ScheduleRuleResponseDto } from './dto/schedule-rule-response.dto.js';
import { UpdateScheduleRuleDto } from './dto/update-schedule-rule.dto.js';
import { ScheduleRulesService } from './schedule-rules.service.js';

const writers = [UserRole.PATIENT, UserRole.CARE_GIVER, UserRole.ADMIN];

type AccessUser = {
  userId: string;
  role: string;
};
const readers = [UserRole.PATIENT, UserRole.CARE_GIVER, UserRole.ADMIN];

@Controller('api/v1')
@ApiTags('Schedule rules')
@ApiCookieAuth('accessToken')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiUnauthorizedResponse({ description: 'Access token cookie is missing or expired.' })
@ApiForbiddenResponse({ description: 'The signed-in role cannot call this route.' })
@ApiResponse({ status: 503, description: 'Medication service is unavailable.' })
export class ScheduleRulesController {
  constructor(private readonly scheduleRulesService: ScheduleRulesService) {}

  @Get('schedule-rules')
  @Role(...readers)
  @ApiOperation({
    summary: 'List dose times for one patient',
    description: 'The patient app uses this list to set local alarms. A patient always receives their own dose times. Each row includes the medicine name, unit, and image stored on the prescription line. Filter isActive with true or false. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiOkResponse({ type: ScheduleRuleResponseDto, isArray: true, description: 'Dose times for the patient, ordered by reminder time.' })
  @ApiBadRequestResponse({ description: 'patientId is missing or is not an ObjectId, or isActive is not true or false.' })
  list(@Query() query: ListScheduleRulesQueryDto, @Req() request: Request) {
    return this.scheduleRulesService.list(query, this.user(request));
  }

  @Get('schedule-rules/:id')
  @Role(...readers)
  @ApiOperation({
    summary: 'Get one dose time',
    description: 'Includes the dose amount and the medicine details from the prescription line. A patient can open only a dose time on their own prescription. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: ScheduleRuleResponseDto })
  @ApiBadRequestResponse({ description: 'id is not a UUID.' })
  @ApiNotFoundResponse({ description: 'Schedule not found.' })
  getById(@Param('id', ParseUUIDPipe) id: string, @Req() request: Request) {
    return this.scheduleRulesService.getById(id, this.user(request));
  }

  @Post('prescription-items/:id/schedules')
  @Role(...writers)
  @ApiOperation({
    summary: 'Add one dose time to a medicine line',
    description: 'Omitted daysOfWeek means every day. An empty daysOfWeek array is rejected. Creating the rule also writes the scheduled dose logs for the prescription date range. A patient can add a dose time only to their own prescription. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid', description: 'Prescription item id' })
  @ApiCreatedResponse({ type: ScheduleRuleResponseDto, description: 'The new dose time.' })
  @ApiBadRequestResponse({ description: 'reminderTime is not HH:mm, or daysOfWeek is empty or outside 1 to 7.' })
  @ApiNotFoundResponse({ description: 'Prescription item not found.' })
  create(@Param('id', ParseUUIDPipe) id: string, @Body() dto: CreateScheduleRuleDto, @Req() request: Request) {
    return this.scheduleRulesService.create(id, dto, this.user(request));
  }

  @Patch('schedule-rules/:id')
  @Role(...writers)
  @ApiOperation({
    summary: 'Change or turn off one dose time',
    description: 'Send reminderTime, daysOfWeek, isActive, or any combination. This does not change the medicine name or dose amount. A patient can change only a dose time on their own prescription. Allowed roles: PATIENT, CARE_GIVER, ADMIN.',
  })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiOkResponse({ type: ScheduleRuleResponseDto, description: 'The dose time after the update.' })
  @ApiBadRequestResponse({ description: 'No field was sent, or a field is invalid.' })
  @ApiNotFoundResponse({ description: 'Schedule not found.' })
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateScheduleRuleDto, @Req() request: Request) {
    return this.scheduleRulesService.update(id, dto, this.user(request));
  }

  private user(request: Request) {
    return (request as Request & { user: AccessUser }).user;
  }
}
