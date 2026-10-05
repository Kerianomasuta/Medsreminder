import { beforeEach, describe, expect, it, vi } from 'vitest';
import { OrderStatus } from '../enums/order-status.enum.js';
import { OrdersService } from './orders.service.js';

const orderId = '11111111-1111-4111-8111-111111111111';

describe('OrdersService', () => {
  const orders = { create: vi.fn(), find: vi.fn(), findOne: vi.fn() };
  let manager: {
    findOne: ReturnType<typeof vi.fn>;
    find: ReturnType<typeof vi.fn>;
    save: ReturnType<typeof vi.fn>;
  };
  let service: OrdersService;

  beforeEach(() => {
    manager = {
      findOne: vi.fn(async () => ({
        id: orderId,
        status: OrderStatus.PENDING_REVIEW,
        pharmacyId: '22222222-2222-4222-8222-222222222222',
        prescriptionId: '33333333-3333-4333-8333-333333333333',
        otpCode: null,
      })),
      find: vi.fn(async () => []),
      save: vi.fn(async (value) => value),
    };
    const dataSource = {
      transaction: vi.fn(async (work: (current: typeof manager) => Promise<unknown>) => work(manager)),
    };
    service = new OrdersService(dataSource as never, orders as never, {} as never, {} as never);
  });

  it('rejects skipping from review straight to delivered', async () => {
    await expect(service.updateStatus(orderId, { status: OrderStatus.DELIVERED })).rejects.toMatchObject({
      message: 'Cannot change status from PENDING_REVIEW to DELIVERED',
    });
    expect(manager.save).not.toHaveBeenCalled();
  });

  it('rejects a cancellation that has no reason', async () => {
    await expect(service.updateStatus(orderId, { status: OrderStatus.CANCELLED })).rejects.toMatchObject({
      message: 'rejectionReason is required to cancel an order',
    });
    expect(manager.save).not.toHaveBeenCalled();
  });
});
