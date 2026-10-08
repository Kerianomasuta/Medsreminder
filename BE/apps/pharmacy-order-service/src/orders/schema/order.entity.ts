import { Column, CreateDateColumn, Entity, Index, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn, type Relation } from 'typeorm';
import { FulfillmentType } from '../../enums/fulfillment-type.enum.js';
import { OrderStatus } from '../../enums/order-status.enum.js';
import { OrderItem } from './order-item.entity.js';

@Entity({ schema: 'pharmacy', name: 'orders' })
@Index('orders_pharmacy_status_idx', ['pharmacyId', 'status'])
@Index('orders_patient_status_idx', ['patientId', 'status'])
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 20, name: 'order_code', unique: true })
  orderCode: string;

  @Column({ type: 'varchar', length: 24, name: 'patient_id' })
  patientId: string;

  @Column({ type: 'varchar', length: 24, name: 'caregiver_id' })
  caregiverId: string;

  @Column({ type: 'uuid', name: 'pharmacy_id' })
  pharmacyId: string;

  @Column({ type: 'uuid', name: 'prescription_id' })
  prescriptionId: string;

  @Column({ type: 'varchar', length: 30, default: OrderStatus.PENDING_REVIEW })
  status: OrderStatus;

  @Column({ type: 'varchar', length: 20, name: 'fulfillment_type' })
  fulfillmentType: FulfillmentType;

  @Column({ type: 'numeric', precision: 12, scale: 2, name: 'total_amount' })
  totalAmount: string;

  @Column({ type: 'varchar', length: 100, name: 'recipient_name', nullable: true })
  recipientName: string | null;

  @Column({ type: 'varchar', length: 15, name: 'recipient_phone', nullable: true })
  recipientPhone: string | null;

  @Column({ type: 'text', name: 'delivery_address', nullable: true })
  deliveryAddress: string | null;

  @Column({ type: 'text', name: 'patient_note', nullable: true })
  patientNote: string | null;

  @Column({ type: 'varchar', length: 100, name: 'shipper_name', nullable: true })
  shipperName: string | null;

  @Column({ type: 'varchar', length: 15, name: 'shipper_phone', nullable: true })
  shipperPhone: string | null;

  @Column({ type: 'text', name: 'rejection_reason', nullable: true })
  rejectionReason: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => OrderItem, (item) => item.order)
  items: Relation<OrderItem>[];
}
