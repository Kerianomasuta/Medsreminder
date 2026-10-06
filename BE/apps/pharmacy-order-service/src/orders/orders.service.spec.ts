import { beforeEach, describe, expect, it, vi } from 'vitest';
import { FulfillmentType } from '../enums/fulfillment-type.enum.js';
import { OrderStatus } from '../enums/order-status.enum.js';
import { PharmacyInventory } from '../pharmacies/schema/pharmacy-inventory.entity.js';
import { Pharmacy } from '../pharmacies/schema/pharmacy.entity.js';
import { OrdersService } from './orders.service.js';
import { OrderItem } from './schema/order-item.entity.js';
import { Order } from './schema/order.entity.js';

const patientId = '11111111-1111-4111-8111-111111111111';
const caregiverId = '22222222-2222-4222-8222-222222222222';
const pharmacyId = '33333333-3333-4333-8333-333333333333';
const prescriptionId = '44444444-4444-4444-8444-444444444444';
const prescriptionItemId = '55555555-5555-4555-8555-555555555555';
const medicineId = '66666666-6666-4666-8666-666666666666';
const orderId = '77777777-7777-4777-8777-777777777777';

function createManager() {
  const inventory = {
    id: 'inv-1',
    pharmacyId,
    medicineId,
    stockQuantity: 10,
    pricePerUnit: '12000.00',
  };
  const orders = new Map<string, Record<string, unknown>>();
  return {
    inventory,
    orders,
    findOne: vi.fn(async (entity: { name: string }, options: { where: { id?: string } }) => {
      if (entity === Pharmacy) {
        return { id: pharmacyId, isActive: true };
      }
      if (entity === PharmacyInventory) {
        return inventory;
      }
      if (entity === Order) {
        return orders.get(options.where.id ?? '') ?? null;
      }
      return null;
    }),
    find: vi.fn(async () => {
      const order = [...orders.values()][0] as { items?: unknown[] } | undefined;
      return order?.items ?? [];
    }),
    create: vi.fn((_entity: unknown, value: Record<string, unknown>) => ({ ...value })),
    save: vi.fn(async (entity: { name: string }, value: Record<string, unknown>) => {
      if (entity === Order) {
        const saved = {
          id: orderId,
          createdAt: new Date('2026-10-03T00:00:00.000Z'),
          updatedAt: new Date('2026-10-03T00:00:00.000Z'),
          items: [],
          ...value,
        };
        orders.set(orderId, saved);
        return saved;
      }
      if (entity === OrderItem) {
        return { id: 'item-1', ...value };
      }
      return value;
    }),
  };
}

describe('OrdersService', () => {
  let manager: ReturnType<typeof createManager>;
  let replenish: ReturnType<typeof vi.fn>;
  let service: OrdersService;

  beforeEach(() => {
    manager = createManager();
    replenish = vi.fn(async () => undefined);
    const dataSource = {
      transaction: vi.fn(async (work: (current: typeof manager) => Promise<unknown>) => work(manager)),
    };
    const orders = { update: vi.fn(async () => undefined), find: vi.fn(), findOne: vi.fn() };
    service = new OrdersService(dataSource as never, orders as never, { replenish } as never);
  });

  it('rejects a delivery order without an address', async () => {
    await expect(service.create({
      ...baseOrder(),
      fulfillmentType: FulfillmentType.DELIVERY,
    })).rejects.toMatchObject({ message: 'recipientName is required' });
  });

  it('reserves stock when the pharmacist accepts the order', async () => {
    const created = await service.create(baseOrder());
    created.items = [{
      id: 'item-1',
      prescriptionItemId,
      medicineId,
      quantity: 4,
      unitPrice: 12000,
    }];
    manager.orders.set(orderId, { ...created, id: orderId, items: created.items });

    const accepted = await service.accept(orderId);

    expect(accepted.status).toBe(OrderStatus.PREPARING);
    expect(manager.inventory.stockQuantity).toBe(6);
  });

  it('refuses to ship a pickup order', async () => {
    manager.orders.set(orderId, {
      id: orderId,
      status: OrderStatus.PREPARING,
      fulfillmentType: FulfillmentType.PICKUP,
      items: [],
    });

    await expect(service.ship(orderId, {})).rejects.toMatchObject({
      message: 'Only a delivery order can be shipped',
    });
  });

  it('stops a caregiver from cancelling after the pharmacy starts packing', async () => {
    manager.orders.set(orderId, {
      id: orderId,
      status: OrderStatus.PREPARING,
      fulfillmentType: FulfillmentType.PICKUP,
      pharmacyId,
      items: [{ medicineId, quantity: 4 }],
    });

    await expect(service.cancel(orderId, {
      actor: 'CAREGIVER',
      rejectionReason: 'Đổi ý',
    })).rejects.toMatchObject({
      message: 'Contact the pharmacy to cancel an order that is already being prepared',
    });
    expect(manager.inventory.stockQuantity).toBe(10);
  });

  it('restores stock when the pharmacist cancels a packed order', async () => {
    manager.orders.set(orderId, {
      id: orderId,
      status: OrderStatus.PREPARING,
      fulfillmentType: FulfillmentType.DELIVERY,
      pharmacyId,
      items: [{ medicineId, quantity: 4 }],
    });

    const cancelled = await service.cancel(orderId, {
      actor: 'PHARMACIST',
      rejectionReason: 'Hết hàng',
    });

    expect(cancelled.status).toBe(OrderStatus.CANCELLED);
    expect(manager.inventory.stockQuantity).toBe(14);
  });

  it('adds the delivered quantity back to the patient stock', async () => {
    manager.orders.set(orderId, {
      id: orderId,
      status: OrderStatus.SHIPPED,
      fulfillmentType: FulfillmentType.DELIVERY,
      items: [{ prescriptionItemId, medicineId, quantity: 4, unitPrice: '12000.00' }],
    });

    const completed = await service.complete(orderId);

    expect(completed.status).toBe(OrderStatus.COMPLETED);
    expect(replenish).toHaveBeenCalledWith([{ prescriptionItemId, quantity: 4 }]);
  });
});

function baseOrder() {
  return {
    patientId,
    caregiverId,
    pharmacyId,
    prescriptionId,
    fulfillmentType: FulfillmentType.PICKUP,
    items: [{
      prescriptionItemId,
      medicineId,
      quantity: 4,
      unitPrice: 12000,
    }],
  };
}
