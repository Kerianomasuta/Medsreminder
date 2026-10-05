import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { OrdersService } from './orders.service.js';

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

@Controller()
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @MessagePattern({ cmd: 'create_order' })
  create(@Payload() payload: CreateOrderMessage) {
    return this.ordersService.create(payload);
  }

  @MessagePattern({ cmd: 'list_orders' })
  list(@Payload() payload: { patientId?: string; caregiverId?: string; pharmacyId?: string; status?: string }) {
    return this.ordersService.list(payload ?? {});
  }

  @MessagePattern({ cmd: 'get_order' })
  getById(@Payload() payload: { id: string }) {
    return this.ordersService.getById(payload.id);
  }

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
  }
}
