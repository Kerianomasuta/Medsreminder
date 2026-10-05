import { randomInt } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';
import { ErrorHandling } from '@lib/error-handling';
import { OrderStatus } from '../enums/order-status.enum.js';
import { PharmacyInventory } from '../inventory/schema/pharmacy-inventory.entity.js';
import { Pharmacy } from '../pharmacies/schema/pharmacy.entity.js';
import { OrderItem } from './schema/order-item.entity.js';
import { Order } from './schema/order.entity.js';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const NEXT_STATUS: Record<OrderStatus, OrderStatus[]> = {
  [OrderStatus.PENDING_REVIEW]: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
  [OrderStatus.PREPARING]: [OrderStatus.READY_FOR_PICKUP, OrderStatus.CANCELLED],
  [OrderStatus.READY_FOR_PICKUP]: [OrderStatus.ASSIGNED, OrderStatus.CANCELLED],
  [OrderStatus.ASSIGNED]: [OrderStatus.IN_TRANSIT, OrderStatus.CANCELLED],
  [OrderStatus.IN_TRANSIT]: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
  [OrderStatus.DELIVERED]: [],
  [OrderStatus.CANCELLED]: [],
};

const STOCK_HELD: OrderStatus[] = [
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.ASSIGNED,
  OrderStatus.IN_TRANSIT,
];

export type OrderItemInput = {
  medicineId?: string;
  quantity?: number;
};

export type CreateOrderInput = {
  patientId?: string;
  caregiverId?: string;
  pharmacyId?: string;
  prescriptionId?: string;
  deliveryAddress?: string;
  deliveryLat?: number | null;
  deliveryLng?: number | null;
  recipientPhone?: string;
  items?: OrderItemInput[];
};

export type UpdateOrderStatusInput = {
  status?: string;
  shipperId?: string;
  rejectionReason?: string;
  otpCode?: string;
  podImageUrl?: string;
};

type PreparedItem = {
  medicineId: string;
  quantity: number;
  unitPrice: string;
};

@Injectable()
export class OrdersService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(Pharmacy)
    private readonly pharmacies: Repository<Pharmacy>,
    @InjectRepository(PharmacyInventory)
    private readonly inventory: Repository<PharmacyInventory>,
  ) {}

  async create(payload: CreateOrderInput) {
    const patientId = this.requireUuid(payload.patientId, 'patientId');
    const caregiverId = this.requireUuid(payload.caregiverId, 'caregiverId');
    const pharmacyId = this.requireUuid(payload.pharmacyId, 'pharmacyId');
    const prescriptionId = this.requireUuid(payload.prescriptionId, 'prescriptionId');
    const deliveryAddress = this.requireText(payload.deliveryAddress, 'deliveryAddress');
    const recipientPhone = this.requireText(payload.recipientPhone, 'recipientPhone');
    const items = await this.prepareItems(pharmacyId, payload.items);
    await this.assertPharmacyAcceptsOrders(pharmacyId);
    await this.assertPrescriptionExists(prescriptionId);

    const total = items.reduce((sum, item) => sum + Number(item.unitPrice) * item.quantity, 0);
    const order = this.orders.create({
      orderCode: this.createOrderCode(),
      patientId,
      caregiverId,
      pharmacyId,
      prescriptionId,
      shipperId: null,
      status: OrderStatus.PENDING_REVIEW,
      totalAmount: total.toFixed(2),
      deliveryAddress,
      deliveryLat: this.optionalCoordinate(payload.deliveryLat, 'deliveryLat', -90, 90),
      deliveryLng: this.optionalCoordinate(payload.deliveryLng, 'deliveryLng', -180, 180),
      recipientPhone,
      otpCode: null,
      podImageUrl: null,
      rejectionReason: null,
    });

    const saved = await this.dataSource.transaction(async (manager) => {
      const created = await manager.save(order);
      const savedItems = [];
      for (const item of items) {
        savedItems.push(await manager.save(OrderItem, manager.create(OrderItem, {
          orderId: created.id,
          medicineId: item.medicineId,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
        })));
      }
      created.items = savedItems;
      return created;
    });

    return this.toOrder(saved, saved.items);
  }

  async list(filter: { patientId?: string; caregiverId?: string; pharmacyId?: string; status?: string }) {
    const where: { patientId?: string; caregiverId?: string; pharmacyId?: string; status?: OrderStatus } = {};
    if (filter.patientId !== undefined) {
      where.patientId = this.requireUuid(filter.patientId, 'patientId');
    }
    if (filter.caregiverId !== undefined) {
      where.caregiverId = this.requireUuid(filter.caregiverId, 'caregiverId');
    }
    if (filter.pharmacyId !== undefined) {
      where.pharmacyId = this.requireUuid(filter.pharmacyId, 'pharmacyId');
    }
    if (filter.status !== undefined) {
      where.status = this.requireStatus(filter.status);
    }
    if (!where.patientId && !where.caregiverId && !where.pharmacyId) {
      throw ErrorHandling.BadRequest('Filter orders by patientId, caregiverId, or pharmacyId');
    }

    const rows = await this.orders.find({
      where,
      relations: { items: true },
      order: { createdAt: 'DESC' },
    });
    return rows.map((row) => this.toOrder(row, row.items ?? []));
  }

  async getById(id: string) {
    const order = await this.findOrder(id);
    return this.toOrder(order, order.items ?? []);
  }

  async updateStatus(id: string, payload: UpdateOrderStatusInput) {
    const next = this.requireStatus(payload.status);
    return this.dataSource.transaction(async (manager) => {
      const order = await manager.findOne(Order, {
        where: { id: this.requireUuid(id, 'order id') },
        lock: { mode: 'pessimistic_write' },
      });
      if (!order) {
        throw ErrorHandling.NotFound('Order not found');
      }
      const items = await manager.find(OrderItem, { where: { orderId: order.id } });
      if (!NEXT_STATUS[order.status].includes(next)) {
        throw ErrorHandling.BadRequest(`Cannot change status from ${order.status} to ${next}`);
      }

      if (next === OrderStatus.CANCELLED) {
        const reason = payload.rejectionReason?.trim();
        if (!reason) {
          throw ErrorHandling.BadRequest('rejectionReason is required to cancel an order');
        }
        if (STOCK_HELD.includes(order.status)) {
          await this.changeStock(manager, order.pharmacyId, items, 1);
        }
        order.rejectionReason = reason;
      }

      if (next === OrderStatus.PREPARING) {
        await this.changeStock(manager, order.pharmacyId, items, -1);
      }

      if (next === OrderStatus.ASSIGNED) {
        order.shipperId = this.requireUuid(payload.shipperId, 'shipperId');
      }

      if (next === OrderStatus.IN_TRANSIT && !order.otpCode) {
        order.otpCode = String(randomInt(0, 10000)).padStart(4, '0');
      }

      if (next === OrderStatus.DELIVERED) {
        this.assertDeliveryProof(order.otpCode, payload.otpCode, payload.podImageUrl);
        if (payload.podImageUrl !== undefined) {
          order.podImageUrl = payload.podImageUrl.trim() || null;
        }
        await this.addPatientStock(manager, order.prescriptionId, items);
      }

      order.status = next;
      const saved = await manager.save(order);
      saved.items = items;
      return this.toOrder(saved, items);
    });
  }

  private async prepareItems(pharmacyId: string, items: OrderItemInput[] | undefined): Promise<PreparedItem[]> {
    if (!items?.length) {
      throw ErrorHandling.BadRequest('An order needs at least one medicine');
    }

    const seen = new Set<string>();
    const prepared: PreparedItem[] = [];
    for (const item of items) {
      const medicineId = this.requireUuid(item.medicineId, 'medicineId');
      if (seen.has(medicineId)) {
        throw ErrorHandling.BadRequest('Each medicine can appear only once in an order');
      }
      seen.add(medicineId);
      const quantity = this.requireQuantity(item.quantity);
      const stock = await this.inventory.findOne({ where: { pharmacyId, medicineId } });
      if (!stock) {
        throw ErrorHandling.NotFound('Medicine is not in this pharmacy inventory');
      }
      if (stock.stockQuantity < quantity) {
        throw ErrorHandling.BadRequest('Not enough stock for this medicine');
      }
      prepared.push({ medicineId, quantity, unitPrice: stock.pricePerUnit });
    }
    return prepared;
  }

  private async changeStock(manager: EntityManager, pharmacyId: string, items: OrderItem[], direction: 1 | -1) {
    for (const item of items) {
      const stock = await manager.findOne(PharmacyInventory, {
        where: { pharmacyId, medicineId: item.medicineId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!stock) {
        throw ErrorHandling.NotFound('Medicine is not in this pharmacy inventory');
      }
      const nextQuantity = stock.stockQuantity + direction * item.quantity;
      if (nextQuantity < 0) {
        throw ErrorHandling.BadRequest('Not enough stock for this medicine');
      }
      stock.stockQuantity = nextQuantity;
      await manager.save(stock);
    }
  }

  private async addPatientStock(manager: EntityManager, prescriptionId: string, items: OrderItem[]) {
    for (const item of items) {
      const rows: Array<{ id: string }> = await manager.query(
        `UPDATE medication.prescription_items
         SET current_stock = current_stock + $1, updated_at = now()
         WHERE prescription_id = $2 AND medicine_id = $3
         RETURNING id`,
        [item.quantity, prescriptionId, item.medicineId],
      );
      if (!rows.length) {
        throw ErrorHandling.NotFound('Prescription does not include this medicine');
      }
    }
  }

  private assertDeliveryProof(expectedOtp: string | null, providedOtp: string | undefined, podImageUrl: string | undefined) {
    const photo = podImageUrl?.trim();
    if (photo) {
      return;
    }
    const otp = providedOtp?.trim();
    if (!otp || otp !== expectedOtp) {
      throw ErrorHandling.BadRequest('Delivery needs the 4-digit OTP or a proof photo');
    }
  }

  private async assertPharmacyAcceptsOrders(pharmacyId: string) {
    const pharmacy = await this.pharmacies.findOne({ where: { id: pharmacyId } });
    if (!pharmacy || !pharmacy.isActive) {
      throw ErrorHandling.NotFound('Pharmacy not found');
    }
  }

  private async assertPrescriptionExists(prescriptionId: string) {
    const rows: Array<{ id: string }> = await this.dataSource.query(
      'SELECT id FROM medication.prescriptions WHERE id = $1',
      [prescriptionId],
    );
    if (!rows.length) {
      throw ErrorHandling.NotFound('Prescription not found');
    }
  }

  private async findOrder(id: string) {
    this.requireUuid(id, 'order id');
    const order = await this.orders.findOne({ where: { id }, relations: { items: true } });
    if (!order) {
      throw ErrorHandling.NotFound('Order not found');
    }
    return order;
  }

  private createOrderCode() {
    const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    return `ORD-${day}-${randomInt(0, 10000).toString().padStart(4, '0')}`;
  }

  private requireStatus(value: string | undefined): OrderStatus {
    if (!value || !Object.values(OrderStatus).includes(value as OrderStatus)) {
      throw ErrorHandling.BadRequest('status is not a valid order status');
    }
    return value as OrderStatus;
  }

  private requireQuantity(value: number | undefined) {
    if (!Number.isInteger(value) || value === undefined || value < 1) {
      throw ErrorHandling.BadRequest('quantity must be a whole number of 1 or more');
    }
    return value;
  }

  private requireUuid(value: string | undefined, label: string) {
    if (!value || !UUID_PATTERN.test(value)) {
      throw ErrorHandling.BadRequest(`${label} must be a UUID`);
    }
    return value;
  }

  private requireText(value: string | undefined, label: string) {
    const trimmed = value?.trim();
    if (!trimmed) {
      throw ErrorHandling.BadRequest(`${label} is required`);
    }
    return trimmed;
  }

  private optionalCoordinate(value: number | null | undefined, label: string, min: number, max: number) {
    if (value == null) {
      return null;
    }
    if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max) {
      throw ErrorHandling.BadRequest(`${label} must be a number from ${min} to ${max}`);
    }
    return value.toFixed(6);
  }

  private toOrder(order: Order, items: OrderItem[]) {
    return {
      id: order.id,
      orderCode: order.orderCode,
      patientId: order.patientId,
      caregiverId: order.caregiverId,
      pharmacyId: order.pharmacyId,
      shipperId: order.shipperId,
      prescriptionId: order.prescriptionId,
      status: order.status,
      totalAmount: Number(order.totalAmount),
      deliveryAddress: order.deliveryAddress,
      deliveryLat: order.deliveryLat == null ? null : Number(order.deliveryLat),
      deliveryLng: order.deliveryLng == null ? null : Number(order.deliveryLng),
      recipientPhone: order.recipientPhone,
      otpCode: order.otpCode,
      podImageUrl: order.podImageUrl,
      rejectionReason: order.rejectionReason,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: items.map((item) => ({
        id: item.id,
        orderId: item.orderId,
        medicineId: item.medicineId,
        quantity: item.quantity,
        unitPrice: Number(item.unitPrice),
      })),
    };
  }
}
