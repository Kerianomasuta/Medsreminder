import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { OrdersService } from './orders.service.js';

@Controller()
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @MessagePattern({ cmd: 'create_order' })
  create(@Payload() payload: Parameters<OrdersService['create']>[0]) {
    return this.ordersService.create(payload);
  }

  @MessagePattern({ cmd: 'list_orders' })
  list(@Payload() payload: Parameters<OrdersService['list']>[0]) {
    return this.ordersService.list(payload);
  }

  @MessagePattern({ cmd: 'get_order' })
  getById(@Payload() payload: { id: string }) {
    return this.ordersService.getById(payload.id);
  }

  @MessagePattern({ cmd: 'accept_order' })
  accept(@Payload() payload: { id: string; pharmacistId?: string }) {
    return this.ordersService.accept(payload.id, payload.pharmacistId);
  }

  @MessagePattern({ cmd: 'reject_order' })
  reject(@Payload() payload: Parameters<OrdersService['reject']>[1] & { id: string }) {
    const { id, ...details } = payload;
    return this.ordersService.reject(id, details);
  }

  @MessagePattern({ cmd: 'ready_order' })
  markReady(@Payload() payload: { id: string }) {
    return this.ordersService.markReady(payload.id);
  }

  @MessagePattern({ cmd: 'ship_order' })
  ship(@Payload() payload: Parameters<OrdersService['ship']>[1] & { id: string }) {
    const { id, ...details } = payload;
    return this.ordersService.ship(id, details);
  }

  @MessagePattern({ cmd: 'complete_order' })
  complete(@Payload() payload: { id: string }) {
    return this.ordersService.complete(payload.id);
  }

  @MessagePattern({ cmd: 'cancel_order' })
  cancel(@Payload() payload: Parameters<OrdersService['cancel']>[1] & { id: string }) {
    const { id, ...details } = payload;
    return this.ordersService.cancel(id, details);
  }
}
