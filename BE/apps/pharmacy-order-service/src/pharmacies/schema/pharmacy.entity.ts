import { Column, CreateDateColumn, Entity, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
<<<<<<< HEAD
import { PharmacyInventory } from './pharmacy-inventory.entity.js';
=======
import { PharmacyInventory } from '../../inventory/schema/pharmacy-inventory.entity.js';
import { Order } from '../../orders/schema/order.entity.js';
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

@Entity({ schema: 'pharmacy', name: 'pharmacies' })
export class Pharmacy {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'pharmacist_id' })
  pharmacistId: string;

<<<<<<< HEAD
  @Column({ type: 'varchar', length: 150 })
  name: string;

  @Column({ type: 'varchar', length: 15, name: 'phone_number' })
  phoneNumber: string;
=======
  @Column({ type: 'text' })
  name: string;

  @Column({ type: 'text' })
  phone: string;
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

  @Column({ type: 'text', name: 'address_text' })
  addressText: string;

<<<<<<< HEAD
  @Column({ type: 'double precision' })
  latitude: number;

  @Column({ type: 'double precision' })
  longitude: number;
=======
  @Column({ type: 'numeric', precision: 9, scale: 6 })
  latitude: string;

  @Column({ type: 'numeric', precision: 9, scale: 6 })
  longitude: string;
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

  @Column({ type: 'boolean', name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => PharmacyInventory, (row) => row.pharmacy)
  inventory: PharmacyInventory[];
<<<<<<< HEAD
=======

  @OneToMany(() => Order, (order) => order.pharmacy)
  orders: Order[];
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
}
