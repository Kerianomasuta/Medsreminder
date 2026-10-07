import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { MedicineUnit } from '../../enums/medicine-unit.enum.js';
import { ScheduleRule } from '../../schedule-rules/schema/schedule-rule.entity.js';
import { Prescription } from './prescription.entity.js';

@Entity({ schema: 'medication', name: 'prescription_items' })
export class PrescriptionItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'prescription_id' })
  prescriptionId: string;

  @Column({ type: 'text' })
  name: string;

  @Column({ type: 'text', name: 'generic_name', nullable: true })
  genericName: string | null;

  @Column({ type: 'enum', enum: MedicineUnit, enumName: 'medicine_unit' })
  unit: MedicineUnit;

  @Column({ type: 'text', name: 'image_url', nullable: true })
  imageUrl: string | null;

  @Column({ type: 'numeric', precision: 10, scale: 2, name: 'dosage_per_time' })
  dosagePerTime: string;

  @Column({ type: 'numeric', precision: 10, scale: 2, name: 'current_stock', default: 0 })
  currentStock: string;

  @Column({ type: 'int', name: 'reorder_threshold', default: 6 })
  reorderThreshold: number;

  @Column({ type: 'text', nullable: true })
  instructions: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => Prescription, (prescription) => prescription.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'prescription_id' })
  prescription: Prescription;

  @OneToMany(() => ScheduleRule, (rule) => rule.prescriptionItem)
  scheduleRules: ScheduleRule[];
}
