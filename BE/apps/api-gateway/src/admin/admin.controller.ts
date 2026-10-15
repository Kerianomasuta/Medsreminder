import { BadRequestException, Body, Controller, Get, Param, Patch, Query, Req, UseGuards } from '@nestjs/common';
import { ApiCookieAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import { Role, UserRole } from '../auth/guards/authorizedByRoles/roles.decorator.js';
import { RolesGuard } from '../auth/guards/authorizedByRoles/roles.guard.js';
import { AdminService } from './admin.service.js';
import { ListAdminLogsQueryDto, ListAdminPrescriptionsQueryDto } from './dto/list-admin-medication.query.js';
import { ListAdminPaymentsQueryDto } from './dto/list-admin-payments.query.js';
import { ListAdminOrdersQueryDto, ListAdminPharmaciesQueryDto } from './dto/list-admin-pharmacy.query.js';
import { ListAdminUsersQueryDto } from './dto/list-admin-users.query.js';
import { UpdateAdminUserDto } from './dto/update-admin-user.dto.js';

type AccessUser = { userId: string };
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

@Controller('api/v1/admin')
@ApiTags('Admin')
@ApiCookieAuth('accessToken')
@UseGuards(JwtAuthGuard, RolesGuard)
@Role(UserRole.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('summary')
  @ApiOperation({ summary: 'Counts of accounts and caregiver links' })
  summary() {
    return this.adminService.summary();
  }

  @Get('users')
  @ApiOperation({ summary: 'Search accounts by role, name, email, or phone' })
  list(@Query() query: ListAdminUsersQueryDto) {
    return this.adminService.list(query);
  }

  @Get('users/:userId')
  @ApiOperation({ summary: 'Account detail and caregiver links' })
  @ApiParam({ name: 'userId', example: '507f1f77bcf86cd799439011' })
  detail(@Param('userId') userId: string) {
    this.requireUserId(userId);
    return this.adminService.detail(userId);
  }

  @Patch('users/:userId')
  @ApiOperation({ summary: 'Change name, phone, role, or lock an account' })
  @ApiParam({ name: 'userId', example: '507f1f77bcf86cd799439011' })
  update(
    @Param('userId') userId: string,
    @Body() body: UpdateAdminUserDto,
    @Req() req: Request,
  ) {
    this.requireUserId(userId);
    const { userId: actorUserId } = (req as Request & { user: AccessUser }).user;
    return this.adminService.update(actorUserId, userId, body);
  }

  @Get('medication/summary')
  @ApiOperation({ summary: 'Counts for prescriptions, medicines, schedules, and dose logs' })
  medicationSummary() {
    return this.adminService.medicationSummary();
  }

  @Get('prescriptions')
  @ApiOperation({ summary: 'Search prescriptions' })
  prescriptions(@Query() query: ListAdminPrescriptionsQueryDto) {
    return this.adminService.listPrescriptions(query);
  }

  @Get('prescriptions/:prescriptionId')
  @ApiOperation({ summary: 'Prescription with medicines and reminder times' })
  @ApiParam({ name: 'prescriptionId' })
  prescription(@Param('prescriptionId') prescriptionId: string) {
    this.requireUuid(prescriptionId, 'Prescription id is invalid');
    return this.adminService.prescription(prescriptionId);
  }

  @Get('medication-logs')
  @ApiOperation({ summary: 'Search dose logs across patients' })
  logs(@Query() query: ListAdminLogsQueryDto) {
    return this.adminService.listLogs(query);
  }

  @Get('pharmacy/summary')
  @ApiOperation({ summary: 'Counts for pharmacies and orders, plus completed order value' })
  pharmacySummary() {
    return this.adminService.pharmacySummary();
  }

  @Get('pharmacies')
  @ApiOperation({ summary: 'Search pharmacies' })
  pharmacies(@Query() query: ListAdminPharmaciesQueryDto) {
    return this.adminService.listPharmacies(query);
  }

  @Get('pharmacies/:pharmacyId')
  @ApiOperation({ summary: 'Pharmacy detail and its order counts' })
  @ApiParam({ name: 'pharmacyId' })
  pharmacy(@Param('pharmacyId') pharmacyId: string) {
    this.requireUuid(pharmacyId, 'Pharmacy id is invalid');
    return this.adminService.pharmacy(pharmacyId);
  }

  @Get('orders')
  @ApiOperation({ summary: 'Search pharmacy orders' })
  orders(@Query() query: ListAdminOrdersQueryDto) {
    return this.adminService.listOrders(query);
  }

  @Get('orders/:orderId')
  @ApiOperation({ summary: 'Order detail and line items' })
  @ApiParam({ name: 'orderId' })
  order(@Param('orderId') orderId: string) {
    this.requireUuid(orderId, 'Order id is invalid');
    return this.adminService.order(orderId);
  }

  @Get('payments/summary')
  @ApiOperation({ summary: 'Premium payment counts and collected amounts' })
  paymentSummary() {
    return this.adminService.paymentSummary();
  }

  @Get('payments')
  @ApiOperation({ summary: 'Search premium payments' })
  payments(@Query() query: ListAdminPaymentsQueryDto) {
    return this.adminService.listPayments(query);
  }

  @Get('payments/:paymentId')
  @ApiOperation({ summary: 'One premium payment and the paying account' })
  @ApiParam({ name: 'paymentId' })
  payment(@Param('paymentId') paymentId: string) {
    this.requireUserId(paymentId, 'Payment id is invalid');
    return this.adminService.payment(paymentId);
  }

  private requireUserId(userId: string, message = 'User id is invalid') {
    if (!/^[0-9a-f]{24}$/i.test(userId)) {
      throw new BadRequestException(message);
    }
  }

  private requireUuid(id: string, message: string) {
    if (!UUID.test(id)) {
      throw new BadRequestException(message);
    }
  }
}
