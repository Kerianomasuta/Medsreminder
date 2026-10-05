import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { ListOrdersQueryDto } from './dto/list-orders.query.js';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto.js';

@Injectable()
export class OrdersService {
  constructor(
    @Inject('PHARMACY_SERVICE')
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

  updateStatus(id: string, dto: UpdateOrderStatusDto) {
    return this.send({ cmd: 'update_order_status' }, { id, ...dto });
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

    if (typeof error === 'object' && error !== null) {
      const record = error as { status?: number; message?: unknown };
      if (typeof record.status === 'number' && typeof record.message === 'string') {
        return new HttpException(record.message, record.status);
      }
    }

    return new HttpException('Pharmacy service is unavailable', HttpStatus.SERVICE_UNAVAILABLE);
  }
}
