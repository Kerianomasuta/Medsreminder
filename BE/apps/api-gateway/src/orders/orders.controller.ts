import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { ListOrdersQueryDto } from './dto/list-orders.query.js';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto.js';
import { OrdersService } from './orders.service.js';

@Controller('api/v1/orders')
@ApiTags('Orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @ApiOperation({ summary: 'Place a medicine order for pharmacist review' })
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

  @Patch(':id/status')
  @ApiOperation({ summary: 'Move an order to the next status' })
  updateStatus(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdateOrderStatusDto) {
    return this.ordersService.updateStatus(id, dto);
  }
}
