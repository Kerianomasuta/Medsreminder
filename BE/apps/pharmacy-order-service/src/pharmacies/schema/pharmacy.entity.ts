import { Column, CreateDateColumn, Entity, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { PharmacyInventory } from './pharmacy-inventory.entity.js';

@Entity({ schema: 'pharmacy', name: 'pharmacies' })
export class Pharmacy {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 24, name: 'pharmacist_id' })
  pharmacistId: string;

  @Column({ type: 'varchar', length: 150 })
  name: string;

  @Column({ type: 'varchar', length: 15, name: 'phone_number' })
  phoneNumber: string;

  @Column({ type: 'text', name: 'address_text' })
  addressText: string;

  @Column({ type: 'double precision' })
  latitude: number;

  @Column({ type: 'double precision' })
  longitude: number;

  @Column({ type: 'boolean', name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => PharmacyInventory, (row) => row.pharmacy)
  inventory: PharmacyInventory[];
}
