<<<<<<< HEAD
import { Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
=======
import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
import { Order } from './order.entity.js';

@Entity({ schema: 'pharmacy', name: 'order_items' })
export class OrderItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'order_id' })
  orderId: string;

<<<<<<< HEAD
  @Column({ type: 'uuid', name: 'prescription_item_id' })
  prescriptionItemId: string;

=======
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  @Column({ type: 'uuid', name: 'medicine_id' })
  medicineId: string;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'numeric', precision: 12, scale: 2, name: 'unit_price' })
  unitPrice: string;

<<<<<<< HEAD
=======
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  @ManyToOne(() => Order, (order) => order.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Order;
}
