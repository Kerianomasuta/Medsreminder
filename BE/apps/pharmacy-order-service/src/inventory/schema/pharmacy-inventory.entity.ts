import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { Pharmacy } from '../../pharmacies/schema/pharmacy.entity.js';

@Entity({ schema: 'pharmacy', name: 'pharmacy_inventory' })
@Index('pharmacy_inventory_pharmacy_medicine_uidx', ['pharmacyId', 'medicineId'], { unique: true })
export class PharmacyInventory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'pharmacy_id' })
  pharmacyId: string;

  @Column({ type: 'uuid', name: 'medicine_id' })
  medicineId: string;

  @Column({ type: 'int', name: 'stock_quantity', default: 0 })
  stockQuantity: number;

  @Column({ type: 'numeric', precision: 12, scale: 2, name: 'price_per_unit' })
  pricePerUnit: string;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => Pharmacy, (pharmacy) => pharmacy.inventory, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'pharmacy_id' })
  pharmacy: Pharmacy;
}
