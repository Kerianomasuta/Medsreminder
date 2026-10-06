import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { OrdersService } from './orders.service.js';

<<<<<<< HEAD
=======
type ItemMessage = {
  medicineId?: string;
  quantity?: number;
};

type CreateOrderMessage = {
  patientId?: string;
  caregiverId?: string;
  pharmacyId?: string;
  prescriptionId?: string;
  deliveryAddress?: string;
  deliveryLat?: number | null;
  deliveryLng?: number | null;
  recipientPhone?: string;
  items?: ItemMessage[];
};

>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
@Controller()
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @MessagePattern({ cmd: 'create_order' })
<<<<<<< HEAD
  create(@Payload() payload: Parameters<OrdersService['create']>[0]) {
=======
  create(@Payload() payload: CreateOrderMessage) {
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
    return this.ordersService.create(payload);
  }

  @MessagePattern({ cmd: 'list_orders' })
<<<<<<< HEAD
  list(@Payload() payload: Parameters<OrdersService['list']>[0]) {
    return this.ordersService.list(payload);
=======
  list(@Payload() payload: { patientId?: string; caregiverId?: string; pharmacyId?: string; status?: string }) {
    return this.ordersService.list(payload ?? {});
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  }

  @MessagePattern({ cmd: 'get_order' })
  getById(@Payload() payload: { id: string }) {
    return this.ordersService.getById(payload.id);
  }

<<<<<<< HEAD
  @MessagePattern({ cmd: 'accept_order' })
  accept(@Payload() payload: { id: string }) {
    return this.ordersService.accept(payload.id);
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
=======
  @MessagePattern({ cmd: 'update_order_status' })
  updateStatus(
    @Payload() payload: {
      id: string;
      status?: string;
      shipperId?: string;
      rejectionReason?: string;
      otpCode?: string;
      podImageUrl?: string;
    },
  ) {
    const { id, ...changes } = payload;
    return this.ordersService.updateStatus(id, changes);
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  }
}
