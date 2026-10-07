import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { MedicineUnit } from '../../enums/medicine-unit.enum.js';

@Entity({ schema: 'medication', name: 'medicines' })
export class Medicine {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text' })
  name: string;

  @Column({ type: 'text', name: 'generic_name', nullable: true })
  genericName: string | null;

  @Column({ type: 'enum', enum: MedicineUnit, enumName: 'medicine_unit' })
  unit: MedicineUnit;

  @Column({ type: 'text', name: 'instruction_note', nullable: true })
  instructionNote: string | null;

  @Column({ type: 'text', name: 'image_url', nullable: true })
  imageUrl: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}