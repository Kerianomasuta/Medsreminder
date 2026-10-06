import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
<<<<<<< HEAD
import { CancelOrderDto, CreateOrderDto, ListOrdersQueryDto, ShipOrderDto } from './dto/create-order.dto.js';
=======
import { CreateOrderDto } from './dto/create-order.dto.js';
import { ListOrdersQueryDto } from './dto/list-orders.query.js';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto.js';
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

@Injectable()
export class OrdersService {
  constructor(
<<<<<<< HEAD
    @Inject('PHARMACY_ORDER_SERVICE')
=======
    @Inject('PHARMACY_SERVICE')
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
    private readonly pharmacyClient: ClientProxy,
  ) {}

  create(dto: CreateOrderDto) {
    return this.send({ cmd: 'create_order' }, dto);
  }

  list(query: ListOrdersQueryDto) {
    return this.send({ cmd: 'list_orders' }, query);
  }

  getById(id: string) {
    return this.send({ cmd: 'get_order' }, { id });
  }

<<<<<<< HEAD
  accept(id: string) {
    return this.send({ cmd: 'accept_order' }, { id });
  }

  markReady(id: string) {
    return this.send({ cmd: 'ready_order' }, { id });
  }

  ship(id: string, dto: ShipOrderDto) {
    return this.send({ cmd: 'ship_order' }, { id, ...dto });
  }

  complete(id: string) {
    return this.send({ cmd: 'complete_order' }, { id });
  }

  cancel(id: string, dto: CancelOrderDto) {
    return this.send({ cmd: 'cancel_order' }, { id, ...dto });
=======
  updateStatus(id: string, dto: UpdateOrderStatusDto) {
    return this.send({ cmd: 'update_order_status' }, { id, ...dto });
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  }

  private async send<T>(pattern: { cmd: string }, payload: unknown): Promise<T> {
    try {
      return await lastValueFrom(this.pharmacyClient.send<T>(pattern, payload));
    } catch (error) {
      throw this.toHttpException(error);
    }
  }

  private toHttpException(error: unknown) {
    if (error instanceof HttpException) {
      return error;
    }
<<<<<<< HEAD
=======

>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
    if (typeof error === 'object' && error !== null) {
      const record = error as { status?: number; message?: unknown };
      if (typeof record.status === 'number' && typeof record.message === 'string') {
        return new HttpException(record.message, record.status);
      }
    }
<<<<<<< HEAD
    return new HttpException('Pharmacy order service is unavailable', HttpStatus.SERVICE_UNAVAILABLE);
=======

    return new HttpException('Pharmacy service is unavailable', HttpStatus.SERVICE_UNAVAILABLE);
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  }
}
