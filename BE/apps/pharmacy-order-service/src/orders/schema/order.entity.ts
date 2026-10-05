import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { OrderStatus } from '../../enums/order-status.enum.js';
import { Pharmacy } from '../../pharmacies/schema/pharmacy.entity.js';
import { OrderItem } from './order-item.entity.js';

@Entity({ schema: 'pharmacy', name: 'orders' })
@Index('orders_pharmacy_status_idx', ['pharmacyId', 'status'])
@Index('orders_shipper_status_idx', ['shipperId', 'status'])
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text', name: 'order_code', unique: true })
  orderCode: string;

  @Column({ type: 'uuid', name: 'patient_id' })
  patientId: string;

  @Column({ type: 'uuid', name: 'caregiver_id' })
  caregiverId: string;

  @Column({ type: 'uuid', name: 'pharmacy_id' })
  pharmacyId: string;

  @Column({ type: 'uuid', name: 'shipper_id', nullable: true })
  shipperId: string | null;

  @Column({ type: 'uuid', name: 'prescription_id' })
  prescriptionId: string;

  @Column({ type: 'enum', enum: OrderStatus, enumName: 'order_status', default: OrderStatus.PENDING_REVIEW })
  status: OrderStatus;

  @Column({ type: 'numeric', precision: 12, scale: 2, name: 'total_amount', default: 0 })
  totalAmount: string;

  @Column({ type: 'text', name: 'delivery_address' })
  deliveryAddress: string;

  @Column({ type: 'numeric', precision: 9, scale: 6, name: 'delivery_lat', nullable: true })
  deliveryLat: string | null;

  @Column({ type: 'numeric', precision: 9, scale: 6, name: 'delivery_lng', nullable: true })
  deliveryLng: string | null;

  @Column({ type: 'text', name: 'recipient_phone' })
  recipientPhone: string;

  @Column({ type: 'varchar', length: 4, name: 'otp_code', nullable: true })
  otpCode: string | null;

  @Column({ type: 'text', name: 'pod_image_url', nullable: true })
  podImageUrl: string | null;

  @Column({ type: 'text', name: 'rejection_reason', nullable: true })
  rejectionReason: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => Pharmacy, (pharmacy) => pharmacy.orders, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'pharmacy_id' })
  pharmacy: Pharmacy;

  @OneToMany(() => OrderItem, (item) => item.order)
  items: OrderItem[];
}
