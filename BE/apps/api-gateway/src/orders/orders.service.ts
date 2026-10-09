import {
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { UserRole } from '../auth/guards/authorizedByRoles/roles.decorator.js';
import {
  CancelOrderDto,
  CreateOrderDto,
  ListOrdersQueryDto,
  RejectOrderDto,
  ShipOrderDto,
} from './dto/create-order.dto.js';

@Injectable()
export class OrdersService {
  constructor(
    @Inject('PHARMACY_ORDER_SERVICE')
    private readonly pharmacyClient: ClientProxy,
  ) {}

  create(dto: CreateOrderDto, caregiverId: string) {
    return this.send({ cmd: 'create_order' }, { ...dto, caregiverId });
  }

  list(query: ListOrdersQueryDto) {
    return this.send({ cmd: 'list_orders' }, query);
  }

  listMine(user: { userId: string; role: string }, status?: string) {
    const scope = status === undefined ? {} : { status };
    if (user.role === UserRole.PATIENT) {
      return this.send(
        { cmd: 'list_orders' },
        { patientId: user.userId, ...scope },
      );
    }
    if (user.role === UserRole.CARE_GIVER) {
      return this.send(
        { cmd: 'list_orders' },
        { caregiverId: user.userId, ...scope },
      );
    }
    if (user.role === UserRole.PHARMACIST) {
      return this.send(
        { cmd: 'list_orders' },
        { pharmacistId: user.userId, ...scope },
      );
    }
    throw new ForbiddenException('You do not have permission');
  }

  getById(id: string) {
    return this.send({ cmd: 'get_order' }, { id });
  }

  accept(id: string, pharmacistId: string) {
    return this.send({ cmd: 'accept_order' }, { id, pharmacistId });
  }

  reject(id: string, dto: RejectOrderDto) {
    return this.send({ cmd: 'reject_order' }, { id, ...dto });
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

  cancel(
    id: string,
    dto: CancelOrderDto,
    user: { userId: string; role: string },
  ) {
    return this.send(
      { cmd: 'cancel_order' },
      {
        id,
        rejectionReason: dto.rejectionReason,
        userId: user.userId,
        role: user.role,
      },
    );
  }

  private async send<T>(
    pattern: { cmd: string },
    payload: unknown,
  ): Promise<T> {
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
      if (
        typeof record.status === 'number' &&
        typeof record.message === 'string'
      ) {
        return new HttpException(record.message, record.status);
      }
    }
    return new HttpException(
      'Pharmacy order service is unavailable',
      HttpStatus.SERVICE_UNAVAILABLE,
    );
  }
}
