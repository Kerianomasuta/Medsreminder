import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiCookieAuth,
  ApiForbiddenResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import {
  Role,
  UserRole,
} from '../auth/guards/authorizedByRoles/roles.decorator.js';
import { RolesGuard } from '../auth/guards/authorizedByRoles/roles.guard.js';
import {
  CancelOrderDto,
  CreateOrderDto,
  ListMyOrdersQueryDto,
  ListOrdersQueryDto,
  RejectOrderDto,
  ShipOrderDto,
} from './dto/create-order.dto.js';
import { OrdersService } from './orders.service.js';

type AccessUser = {
  userId: string;
  role: string;
};

@Controller('api/v1/orders')
@ApiTags('Orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) { }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Role(UserRole.CARE_GIVER)
  @ApiCookieAuth('accessToken')
  @ApiOperation({
    summary: 'Submit a prescription order for a nearby pharmacy to review',
  })
  create(@Body() dto: CreateOrderDto, @Req() request: Request) {
    const user = (request as Request & { user: AccessUser }).user;
    return this.ordersService.create(dto, user.userId);
  }

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Role(UserRole.ADMIN)
  @ApiCookieAuth('accessToken')
  @ApiOperation({
    summary: 'List orders by patient, caregiver, pharmacy, or status',
    description:
      'Admin only. At least one filter is required. Allowed role: ADMIN.',
  })
  @ApiUnauthorizedResponse({
    description: 'Access token cookie is missing or expired.',
  })
  @ApiForbiddenResponse({
    description: 'Only an admin can list orders by an arbitrary id.',
  })
  list(@Query() query: ListOrdersQueryDto) {
    return this.ordersService.list(query);
  }

  @Get('mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Role(UserRole.PATIENT, UserRole.CARE_GIVER, UserRole.PHARMACIST)
  @ApiCookieAuth('accessToken')
  @ApiOperation({
    summary: "List the signed-in user's orders",
    description:
      'The owner id comes from the access token. A patient sees orders for that patient, a caregiver sees orders they submitted, and a pharmacist sees orders for their pharmacies. Optional status narrows the list. Allowed roles: PATIENT, CARE_GIVER, PHARMACIST.',
  })
  @ApiUnauthorizedResponse({
    description: 'Access token cookie is missing or expired.',
  })
  @ApiForbiddenResponse({
    description: 'The signed-in role cannot call this route.',
  })
  listMine(@Req() request: Request, @Query() query: ListMyOrdersQueryDto) {
    const user = (request as Request & { user: AccessUser }).user;
    return this.ordersService.listMine(user, query.status);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one order' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.getById(id);
  }

  @Post(':id/accept')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Role(UserRole.PHARMACIST)
  @ApiCookieAuth('accessToken')
  @ApiOperation({
    summary: 'Pharmacy accepts a submitted order',
    description:
      'The signed-in user must be a pharmacist, and the order pharmacy must belong to that pharmacist. Allowed role: PHARMACIST.',
  })
  @ApiUnauthorizedResponse({
    description: 'Access token cookie is missing or expired.',
  })
  @ApiForbiddenResponse({
    description:
      'The account is not a pharmacist, or the order belongs to another pharmacy.',
  })
  accept(@Param('id', ParseUUIDPipe) id: string, @Req() request: Request) {
    const user = (request as Request & { user: AccessUser }).user;
    return this.ordersService.accept(id, user.userId);
  }

  @Post(':id/reject')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Role(UserRole.PHARMACIST)
  @ApiCookieAuth('accessToken')
  @ApiOperation({
    summary: 'Pharmacy rejects a submitted order and must give a reason',
  })
  reject(@Param('id', ParseUUIDPipe) id: string, @Body() dto: RejectOrderDto) {
    return this.ordersService.reject(id, dto);
  }

  @Post(':id/ready')
  @ApiOperation({
    summary:
      'Mark a packed pickup order as waiting for the patient. Stock is not added yet',
  })
  markReady(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.markReady(id);
  }

  @Post(':id/ship')
  @ApiOperation({
    summary:
      'Hand a packed delivery order to a shipper. Stock is not added yet',
  })
  ship(@Param('id', ParseUUIDPipe) id: string, @Body() dto: ShipOrderDto) {
    return this.ordersService.ship(id, dto);
  }

  @Post(':id/complete')
  @ApiOperation({
    summary:
      'Patient received the medicine. Status becomes COMPLETED and home stock is replenished',
    description:
      'A pickup order must be READY_FOR_PICKUP. A delivery order must be SHIPPED. A no-show or a failed delivery is cancelled instead, and home stock is not changed.',
  })
  complete(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.complete(id);
  }

  @Post(':id/cancel')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Role(UserRole.CARE_GIVER, UserRole.PHARMACIST)
  @ApiCookieAuth('accessToken')
  @ApiOperation({
    summary: 'Cancel an order that was not received',
    description:
      "The caller comes from the access token. A caregiver can cancel only their own order while it is PENDING_REVIEW. A pharmacist can cancel their pharmacy's order only after accepting it. A submitted order is rejected, not cancelled. Cancel does not add home stock. Allowed roles: CARE_GIVER, PHARMACIST.",
  })
  @ApiUnauthorizedResponse({
    description: 'Access token cookie is missing or expired.',
  })
  @ApiForbiddenResponse({
    description: 'The signed-in user does not own this order.',
  })
  cancel(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CancelOrderDto,
    @Req() request: Request,
  ) {
    const user = (request as Request & { user: AccessUser }).user;
    return this.ordersService.cancel(id, dto, user);
  }
}
