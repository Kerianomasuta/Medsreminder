import { Column, CreateDateColumn, Entity, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { PharmacyInventory } from '../../inventory/schema/pharmacy-inventory.entity.js';
import { Order } from '../../orders/schema/order.entity.js';

@Entity({ schema: 'pharmacy', name: 'pharmacies' })
export class Pharmacy {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'pharmacist_id' })
  pharmacistId: string;

  @Column({ type: 'text' })
  name: string;

  @Column({ type: 'text' })
  phone: string;

  @Column({ type: 'text', name: 'address_text' })
  addressText: string;

  @Column({ type: 'numeric', precision: 9, scale: 6 })
  latitude: string;

  @Column({ type: 'numeric', precision: 9, scale: 6 })
  longitude: string;

  @Column({ type: 'boolean', name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => PharmacyInventory, (row) => row.pharmacy)
  inventory: PharmacyInventory[];

  @OneToMany(() => Order, (order) => order.pharmacy)
  orders: Order[];
}
