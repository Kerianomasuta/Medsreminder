import { Body, Controller, Get, Param, ParseUUIDPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CancelOrderDto, CreateOrderDto, ListOrdersQueryDto, RejectOrderDto, ShipOrderDto } from './dto/create-order.dto.js';
import { OrdersService } from './orders.service.js';

@Controller('api/v1/orders')
@ApiTags('Orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @ApiOperation({ summary: 'Submit a prescription order for a pharmacy to review' })
  create(@Body() dto: CreateOrderDto) {
    return this.ordersService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List orders for a patient, caregiver, or pharmacy' })
  list(@Query() query: ListOrdersQueryDto) {
    return this.ordersService.list(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one order' })
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.getById(id);
  }

  @Post(':id/accept')
  @ApiOperation({ summary: 'Pharmacy accepts a submitted order' })
  accept(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.accept(id);
  }

  @Post(':id/reject')
  @ApiOperation({ summary: 'Pharmacy rejects a submitted order and must give a reason' })
  reject(@Param('id', ParseUUIDPipe) id: string, @Body() dto: RejectOrderDto) {
    return this.ordersService.reject(id, dto);
  }

  @Post(':id/ready')
  @ApiOperation({ summary: 'Pickup order is packed and waiting at the counter' })
  markReady(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.markReady(id);
  }

  @Post(':id/ship')
  @ApiOperation({ summary: 'Delivery order was handed to an outside courier' })
  ship(@Param('id', ParseUUIDPipe) id: string, @Body() dto: ShipOrderDto) {
    return this.ordersService.ship(id, dto);
  }

  @Post(':id/complete')
  @ApiOperation({ summary: 'Medicine was received and personal stock is replenished' })
  complete(@Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.complete(id);
  }

  @Post(':id/cancel')
  @ApiOperation({ summary: 'Cancel an order. A caregiver can cancel only before the pharmacy accepts it' })
  cancel(@Param('id', ParseUUIDPipe) id: string, @Body() dto: CancelOrderDto) {
    return this.ordersService.cancel(id, dto);
  }
}
