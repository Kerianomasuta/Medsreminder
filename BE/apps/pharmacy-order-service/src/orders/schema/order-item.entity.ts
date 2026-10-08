import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn, type Relation } from 'typeorm';
import { Order } from './order.entity.js';

@Entity({ schema: 'pharmacy', name: 'order_items' })
export class OrderItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'order_id' })
  orderId: string;

  @Column({ type: 'uuid', name: 'prescription_item_id' })
  prescriptionItemId: string;

  @Column({ type: 'text' })
  name: string;

  @Column({ type: 'text' })
  unit: string;

  @Column({ type: 'text', name: 'image_url', nullable: true })
  imageUrl: string | null;

  @Column({ type: 'uuid', name: 'medicine_id', nullable: true })
  medicineId: string | null;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'numeric', precision: 12, scale: 2, name: 'unit_price', nullable: true })
  unitPrice: string | null;

  @ManyToOne(() => Order, (order) => order.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Relation<Order>;
}
