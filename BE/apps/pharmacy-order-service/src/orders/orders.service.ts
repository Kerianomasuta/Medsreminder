import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, FindOptionsWhere, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { FulfillmentType } from '../enums/fulfillment-type.enum.js';
import { OrderStatus } from '../enums/order-status.enum.js';
import { Pharmacy } from '../pharmacies/schema/pharmacy.entity.js';
import { MedicationStockClient } from './medication-stock.client.js';
import { OrderItem } from './schema/order-item.entity.js';
import { Order } from './schema/order.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export type OrderItemInput = {
  prescriptionItemId?: string;
  quantity?: number;
};

export type CreateOrderInput = {
  patientId?: string;
  caregiverId?: string;
  pharmacyId?: string;
  prescriptionId?: string;
  fulfillmentType?: string;
  recipientName?: string | null;
  recipientPhone?: string | null;
  deliveryAddress?: string | null;
  patientNote?: string | null;
  items?: OrderItemInput[];
};

export type ListOrdersInput = {
  patientId?: string;
  caregiverId?: string;
  pharmacyId?: string;
  status?: string;
};

export type ShipOrderInput = {
  shippingCarrier?: string | null;
  trackingCodeOrLink?: string | null;
};

export type CancelOrderInput = {
  rejectionReason?: string;
  actor?: string;
};

type PreparedItem = {
  prescriptionItemId: string;
  name: string;
  unit: string;
  imageUrl: string | null;
  quantity: number;
};

export type RejectOrderInput = {
  rejectionReason?: string;
};

@Injectable()
export class OrdersService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    private readonly medicationStock: MedicationStockClient,
  ) {}

  async create(payload: CreateOrderInput) {
    const fulfillmentType = this.requireFulfillment(payload.fulfillmentType);
    const recipient = this.prepareRecipient(fulfillmentType, payload);
    const requested = this.prepareItems(payload.items);
    const pharmacyId = this.requireUuid(payload.pharmacyId, 'pharmacyId');
    const prescriptionId = this.requireUuid(payload.prescriptionId, 'prescriptionId');

    return this.dataSource.transaction(async (manager) => {
      const pharmacy = await manager.findOne(Pharmacy, { where: { id: pharmacyId } });
      if (!pharmacy?.isActive) {
        throw ErrorHandling.NotFound('Pharmacy not found');
      }
      const items = await this.loadPrescriptionLines(manager, prescriptionId, requested);

      const saved = await manager.save(
        Order,
        manager.create(Order, {
          orderCode: this.createOrderCode(),
          patientId: this.requireUuid(payload.patientId, 'patientId'),
          caregiverId: this.requireUuid(payload.caregiverId, 'caregiverId'),
          pharmacyId,
          prescriptionId,
          status: OrderStatus.PENDING_REVIEW,
          fulfillmentType,
          totalAmount: '0.00',
          ...recipient,
          patientNote: this.optionalText(payload.patientNote),
        }),
      );

      const savedItems = [];
      for (const item of items) {
        savedItems.push(await manager.save(OrderItem, manager.create(OrderItem, {
          orderId: saved.id,
          ...item,
        })));
      }
      saved.items = savedItems;
      return this.toOrder(saved);
    });
  }

  async list(query: ListOrdersInput = {}) {
    const where: FindOptionsWhere<Order> = {};
    if (query.patientId !== undefined) {
      where.patientId = this.requireUuid(query.patientId, 'patientId');
    }
    if (query.caregiverId !== undefined) {
      where.caregiverId = this.requireUuid(query.caregiverId, 'caregiverId');
    }
    if (query.pharmacyId !== undefined) {
      where.pharmacyId = this.requireUuid(query.pharmacyId, 'pharmacyId');
    }
    if (query.status !== undefined) {
      where.status = this.requireStatus(query.status);
    }
    if (Object.keys(where).length === 0) {
      throw ErrorHandling.BadRequest('Filter orders by patientId, caregiverId, pharmacyId, or status');
    }

    const rows = await this.orders.find({
      where,
      relations: { items: true },
      order: { createdAt: 'DESC' },
    });
    return rows.map((row) => this.toOrder(row));
  }

  async getById(id: string) {
    return this.toOrder(await this.findOrder(id));
  }

  async accept(id: string) {
    return this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, id);
      this.assertStatus(order, OrderStatus.PENDING_REVIEW, 'Only a submitted order can be accepted');
      order.status = OrderStatus.PREPARING;
      return this.toOrder(await manager.save(Order, order));
    });
  }

  async reject(id: string, payload: RejectOrderInput) {
    const reason = this.requireText(payload.rejectionReason, 'rejectionReason', 2000);
    return this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, id);
      this.assertStatus(order, OrderStatus.PENDING_REVIEW, 'Only a submitted order can be rejected');
      order.status = OrderStatus.CANCELLED;
      order.rejectionReason = reason;
      return this.toOrder(await manager.save(Order, order));
    });
  }

  async markReady(id: string) {
    return this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, id);
      if (order.fulfillmentType !== FulfillmentType.PICKUP) {
        throw ErrorHandling.BadRequest('Only a pickup order can be marked ready for pickup');
      }
      this.assertStatus(order, OrderStatus.PREPARING, 'Pack the order before marking it ready');
      order.status = OrderStatus.READY_FOR_PICKUP;
      return this.toOrder(await manager.save(Order, order));
    });
  }

  async ship(id: string, payload: ShipOrderInput = {}) {
    return this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, id);
      if (order.fulfillmentType !== FulfillmentType.DELIVERY) {
        throw ErrorHandling.BadRequest('Only a delivery order can be shipped');
      }
      this.assertStatus(order, OrderStatus.PREPARING, 'Pack the order before shipping it');
      order.status = OrderStatus.SHIPPED;
      order.shippingCarrier = this.optionalText(payload.shippingCarrier);
      order.trackingCodeOrLink = this.optionalText(payload.trackingCodeOrLink);
      return this.toOrder(await manager.save(Order, order));
    });
  }

  async complete(id: string) {
    const completed = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, id);
      const expected = order.fulfillmentType === FulfillmentType.PICKUP
        ? OrderStatus.READY_FOR_PICKUP
        : OrderStatus.SHIPPED;
      this.assertStatus(order, expected, 'The order is not ready to complete');
      order.status = OrderStatus.COMPLETED;
      return this.toOrder(await manager.save(Order, order));
    });

    try {
      await this.medicationStock.replenish(completed.items.map((item) => ({
        prescriptionItemId: item.prescriptionItemId,
        quantity: item.quantity,
      })));
    } catch (error) {
      await this.orders.update(completed.id, {
        status: completed.fulfillmentType === FulfillmentType.PICKUP
          ? OrderStatus.READY_FOR_PICKUP
          : OrderStatus.SHIPPED,
      });
      throw error;
    }

    return completed;
  }

  async cancel(id: string, payload: CancelOrderInput) {
    const reason = this.requireText(payload.rejectionReason, 'rejectionReason', 2000);
    const actor = this.requireActor(payload.actor);

    return this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, id);
      if (order.status === OrderStatus.COMPLETED || order.status === OrderStatus.CANCELLED) {
        throw ErrorHandling.BadRequest('This order can no longer be cancelled');
      }
      if (actor === 'CAREGIVER' && order.status !== OrderStatus.PENDING_REVIEW) {
        throw ErrorHandling.Forbidden('Contact the pharmacy to cancel an order that is already being prepared');
      }
      order.status = OrderStatus.CANCELLED;
      order.rejectionReason = reason;
      return this.toOrder(await manager.save(Order, order));
    });
  }

  private async findOrder(id: string) {
    const orderId = this.requireUuid(id, 'orderId');
    const order = await this.orders.findOne({
      where: { id: orderId },
      relations: { items: true },
    });
    if (!order) {
      throw ErrorHandling.NotFound('Order not found');
    }
    return order;
  }

  private async lockOrder(manager: EntityManager, id: string) {
    const orderId = this.requireUuid(id, 'orderId');
    const order = await manager.findOne(Order, {
      where: { id: orderId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!order) {
      throw ErrorHandling.NotFound('Order not found');
    }
    order.items = await manager.find(OrderItem, { where: { orderId: order.id } });
    return order;
  }

  private prepareItems(items: OrderItemInput[] | undefined) {
    if (!items?.length) {
      throw ErrorHandling.BadRequest('An order needs at least one medicine');
    }
    const seenItems = new Set<string>();
    return items.map((item) => {
      const prescriptionItemId = this.requireUuid(item.prescriptionItemId, 'prescriptionItemId');
      if (seenItems.has(prescriptionItemId)) {
        throw ErrorHandling.BadRequest('Each prescription medicine can appear only once in an order');
      }
      seenItems.add(prescriptionItemId);
      const quantity = item.quantity;
      if (typeof quantity !== 'number' || !Number.isInteger(quantity) || quantity < 1) {
        throw ErrorHandling.BadRequest('quantity must be a whole number of at least 1');
      }
      return { prescriptionItemId, quantity };
    });
  }

  private async loadPrescriptionLines(
    manager: EntityManager,
    prescriptionId: string,
    items: Array<{ prescriptionItemId: string; quantity: number }>,
  ): Promise<PreparedItem[]> {
    const lines: PreparedItem[] = [];
    for (const item of items) {
      const rows: Array<{ id: string; name: string; unit: string; image_url: string | null }> = await manager.query(
        `SELECT id, name, unit::text AS unit, image_url
         FROM medication.prescription_items
         WHERE id = $1 AND prescription_id = $2`,
        [item.prescriptionItemId, prescriptionId],
      );
      const line = rows[0];
      if (!line) {
        throw ErrorHandling.NotFound('Prescription item not found');
      }
      lines.push({
        prescriptionItemId: item.prescriptionItemId,
        name: line.name,
        unit: line.unit,
        imageUrl: line.image_url,
        quantity: item.quantity,
      });
    }
    return lines;
  }

  private prepareRecipient(fulfillmentType: FulfillmentType, payload: CreateOrderInput) {
    if (fulfillmentType === FulfillmentType.PICKUP) {
      if (payload.recipientName || payload.recipientPhone || payload.deliveryAddress) {
        throw ErrorHandling.BadRequest('A pickup order does not take a delivery address');
      }
      return { recipientName: null, recipientPhone: null, deliveryAddress: null };
    }

    return {
      recipientName: this.requireText(payload.recipientName ?? undefined, 'recipientName', 100),
      recipientPhone: this.requireText(payload.recipientPhone ?? undefined, 'recipientPhone', 15),
      deliveryAddress: this.requireText(payload.deliveryAddress ?? undefined, 'deliveryAddress', 2000),
    };
  }

  private createOrderCode() {
    let code = 'MD';
    for (let index = 0; index < 8; index += 1) {
      code += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
    }
    return code;
  }

  private assertStatus(order: Order, expected: OrderStatus, message: string) {
    if (order.status !== expected) {
      throw ErrorHandling.BadRequest(message);
    }
  }

  private toOrder(order: Order) {
    return {
      id: order.id,
      orderCode: order.orderCode,
      patientId: order.patientId,
      caregiverId: order.caregiverId,
      pharmacyId: order.pharmacyId,
      prescriptionId: order.prescriptionId,
      status: order.status,
      fulfillmentType: order.fulfillmentType,
      totalAmount: Number(order.totalAmount),
      recipientName: order.recipientName,
      recipientPhone: order.recipientPhone,
      deliveryAddress: order.deliveryAddress,
      patientNote: order.patientNote,
      shippingCarrier: order.shippingCarrier,
      trackingCodeOrLink: order.trackingCodeOrLink,
      rejectionReason: order.rejectionReason,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: [...(order.items ?? [])].map((item) => ({
        id: item.id,
        prescriptionItemId: item.prescriptionItemId,
        name: item.name,
        unit: item.unit,
        imageUrl: item.imageUrl,
        quantity: item.quantity,
      })),
    };
  }

  private requireFulfillment(value: string | undefined): FulfillmentType {
    if (value !== FulfillmentType.PICKUP && value !== FulfillmentType.DELIVERY) {
      throw ErrorHandling.BadRequest('fulfillmentType must be PICKUP or DELIVERY');
    }
    return value;
  }

  private requireStatus(value: string): OrderStatus {
    if (!Object.values(OrderStatus).includes(value as OrderStatus)) {
      throw ErrorHandling.BadRequest('status is not a valid order status');
    }
    return value as OrderStatus;
  }

  private requireActor(value: string | undefined) {
    if (value !== 'CAREGIVER' && value !== 'PHARMACIST') {
      throw ErrorHandling.BadRequest('actor must be CAREGIVER or PHARMACIST');
    }
    return value;
  }

  private requireUuid(value: string | undefined, label: string) {
    if (!value || !UUID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be a UUID`);
    }
    return value;
  }

  private requireText(value: string | undefined, label: string, maxLength: number) {
    const trimmed = value?.trim() ?? '';
    if (!trimmed) {
      throw ErrorHandling.BadRequest(`${label} is required`);
    }
    if (trimmed.length > maxLength) {
      throw ErrorHandling.BadRequest(`${label} must be at most ${maxLength} characters`);
    }
    return trimmed;
  }

  private optionalText(value: string | null | undefined) {
    if (value == null) {
      return null;
    }
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
  }

}
