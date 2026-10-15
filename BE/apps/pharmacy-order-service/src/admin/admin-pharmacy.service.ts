import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { countsFor, likePattern, numberOrNull, pageWindow, vietnamRange } from '@lib/admin-query';
import { ErrorHandling } from '@lib/error-handling';
import { In, MoreThanOrEqual, Repository } from 'typeorm';
import { OrderStatus } from '../enums/order-status.enum.js';
import { OrderItem } from '../orders/schema/order-item.entity.js';
import { Order } from '../orders/schema/order.entity.js';
import { Pharmacy } from '../pharmacies/schema/pharmacy.entity.js';

const ORDER_STATUSES = Object.values(OrderStatus);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type ListInput = {
  q?: string;
  status?: string;
  pharmacyId?: string;
  patientId?: string;
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
};

@Injectable()
export class AdminPharmacyService {
  constructor(
    @InjectRepository(Pharmacy)
    private readonly pharmacies: Repository<Pharmacy>,
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly orderItems: Repository<OrderItem>,
  ) {}

  async summary() {
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const [pharmacyTotal, pharmacyRecent, orderRows, ordersRecent, completed] = await Promise.all([
      this.pharmacies.count(),
      this.pharmacies.count({ where: { createdAt: MoreThanOrEqual(weekAgo) } }),
      this.orders.createQueryBuilder('ord').select('ord.status', 'status').addSelect('COUNT(*)', 'count').groupBy('ord.status').getRawMany<Record<string, unknown>>(),
      this.orders.count({ where: { createdAt: MoreThanOrEqual(weekAgo) } }),
      this.orders.createQueryBuilder('ord')
        .select('COALESCE(SUM(ord.totalAmount), 0)', 'amount')
        .where('ord.status = :status', { status: OrderStatus.COMPLETED })
        .getRawOne<Record<string, unknown>>(),
    ]);
    const orders = countsFor(ORDER_STATUSES, orderRows.map((row) => ({
      key: String(raw(row, 'status') ?? ''),
      count: Number(raw(row, 'count') ?? 0),
    })));
    return {
      pharmacies: { total: pharmacyTotal, createdLast7Days: pharmacyRecent },
      orders: {
        total: orders.total,
        byStatus: orders.byStatus,
        createdLast7Days: ordersRecent,
        completedAmount: numberOrNull(raw(completed, 'amount')) ?? 0,
      },
    };
  }

  async listPharmacies(input: ListInput) {
    const window = pageWindow(input.page, input.limit);
    const query = this.pharmacies.createQueryBuilder('pharmacy').orderBy('pharmacy.createdAt', 'DESC');
    const pattern = likePattern(input.q);
    if (pattern) {
      query.andWhere(
        `(pharmacy.name ILIKE :pattern ESCAPE '\\' OR pharmacy.phoneNumber ILIKE :pattern ESCAPE '\\' OR pharmacy.addressText ILIKE :pattern ESCAPE '\\')`,
        { pattern },
      );
    }
    const [rows, total] = await query.skip(window.skip).take(window.limit).getManyAndCount();
    return {
      page: window.page,
      limit: window.limit,
      total,
      pharmacies: rows.map((row) => this.pharmacyBrief(row)),
    };
  }

  async pharmacyDetail(id?: string) {
    const pharmacyId = this.requireUuid(id, 'Pharmacy id is invalid');
    const pharmacy = await this.pharmacies.findOne({ where: { id: pharmacyId } });
    if (!pharmacy) {
      throw ErrorHandling.NotFound('Pharmacy not found');
    }
    const rows = await this.orders.createQueryBuilder('ord')
      .select('ord.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .where('ord.pharmacyId = :pharmacyId', { pharmacyId })
      .groupBy('ord.status')
      .getRawMany<Record<string, unknown>>();
    const orders = countsFor(ORDER_STATUSES, rows.map((row) => ({
      key: String(raw(row, 'status') ?? ''),
      count: Number(raw(row, 'count') ?? 0),
    })));
    return { pharmacy: this.pharmacyBrief(pharmacy), orders: { total: orders.total, byStatus: orders.byStatus } };
  }

  async listOrders(input: ListInput) {
    const window = pageWindow(input.page, input.limit);
    this.optionalStatus(input.status);
    const pharmacyId = this.optionalUuid(input.pharmacyId, 'Pharmacy id is invalid');
    const patientId = this.optionalPatient(input.patientId);
    const range = vietnamRange(input.from, input.to);
    if ('error' in range) {
      throw ErrorHandling.BadRequest(range.error);
    }
    const query = this.orders.createQueryBuilder('ord').orderBy('ord.createdAt', 'DESC');
    if (input.status) {
      query.andWhere('ord.status = :status', { status: input.status });
    }
    if (pharmacyId) {
      query.andWhere('ord.pharmacyId = :pharmacyId', { pharmacyId });
    }
    if (patientId) {
      query.andWhere('ord.patientId = :patientId', { patientId });
    }
    const pattern = likePattern(input.q);
    if (pattern) {
      query.andWhere(`ord.orderCode ILIKE :pattern ESCAPE '\\'`, { pattern });
    }
    if (range.from) {
      query.andWhere('ord.createdAt >= :from', { from: range.from });
    }
    if (range.toExclusive) {
      query.andWhere('ord.createdAt < :to', { to: range.toExclusive });
    }
    const [rows, total] = await query.skip(window.skip).take(window.limit).getManyAndCount();
    const names = await this.pharmacyNames(rows.map((row) => row.pharmacyId));
    return {
      page: window.page,
      limit: window.limit,
      total,
      orders: rows.map((row) => ({
        ...this.orderBrief(row),
        pharmacyName: names.get(row.pharmacyId) ?? null,
      })),
    };
  }

  async orderDetail(id?: string) {
    const orderId = this.requireUuid(id, 'Order id is invalid');
    const order = await this.orders.findOne({ where: { id: orderId } });
    if (!order) {
      throw ErrorHandling.NotFound('Order not found');
    }
    const [pharmacy, items] = await Promise.all([
      this.pharmacies.findOne({ where: { id: order.pharmacyId } }),
      this.orderItems.find({ where: { orderId }, order: { name: 'ASC' } }),
    ]);
    return {
      order: {
        ...this.orderBrief(order),
        pharmacyName: pharmacy?.name ?? null,
        recipientName: order.recipientName,
        recipientPhone: order.recipientPhone,
        deliveryAddress: order.deliveryAddress,
        patientNote: order.patientNote,
        shipperName: order.shipperName,
        shipperPhone: order.shipperPhone,
        rejectionReason: order.rejectionReason,
      },
      items: items.map((item) => ({
        id: item.id,
        prescriptionItemId: item.prescriptionItemId,
        name: item.name,
        unit: item.unit,
        quantity: item.quantity,
        unitPrice: numberOrNull(item.unitPrice),
      })),
    };
  }

  private pharmacyBrief(row: Pharmacy) {
    return {
      id: row.id,
      pharmacistId: row.pharmacistId,
      name: row.name,
      phoneNumber: row.phoneNumber,
      addressText: row.addressText,
      latitude: row.latitude,
      longitude: row.longitude,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private orderBrief(row: Order) {
    return {
      id: row.id,
      orderCode: row.orderCode,
      patientId: row.patientId,
      caregiverId: row.caregiverId,
      pharmacyId: row.pharmacyId,
      prescriptionId: row.prescriptionId,
      status: row.status,
      fulfillmentType: row.fulfillmentType,
      totalAmount: numberOrNull(row.totalAmount),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private async pharmacyNames(ids: string[]) {
    const names = new Map<string, string>();
    const unique = [...new Set(ids)];
    if (unique.length === 0) {
      return names;
    }
    const rows = await this.pharmacies.find({ where: { id: In(unique) }, select: { id: true, name: true } });
    for (const row of rows) {
      names.set(row.id, row.name);
    }
    return names;
  }

  private optionalStatus(status?: string) {
    if (status && !ORDER_STATUSES.includes(status as OrderStatus)) {
      throw ErrorHandling.BadRequest('Order status is not supported');
    }
  }

  private optionalUuid(id: string | undefined, message: string) {
    if (!id) {
      return undefined;
    }
    return this.requireUuid(id, message);
  }

  private optionalPatient(patientId?: string) {
    if (!patientId) {
      return undefined;
    }
    if (!/^[0-9a-f]{24}$/i.test(patientId)) {
      throw ErrorHandling.BadRequest('Patient id is invalid');
    }
    return patientId;
  }

  private requireUuid(id: string | undefined, message: string) {
    if (!id || !UUID.test(id)) {
      throw ErrorHandling.BadRequest(message);
    }
    return id;
  }
}

function raw(row: Record<string, unknown> | undefined, ...keys: string[]) {
  for (const key of keys) {
    const value = row?.[key];
    if (value !== undefined && value !== null) {
      return value;
    }
  }
  return undefined;
}
