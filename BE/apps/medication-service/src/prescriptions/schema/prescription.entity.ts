import { Column, CreateDateColumn, Entity, Index, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { PrescriptionItem } from './prescription-item.entity.js';

@Entity({ schema: 'medication', name: 'prescriptions' })
@Index('prescriptions_patient_idx', ['patientId', 'isActive'])
export class Prescription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'patient_id' })
  patientId: string;

  @Column({ type: 'uuid', name: 'created_by_cg_id' })
  createdByCgId: string;

  @Column({ type: 'text' })
  title: string;

  @Column({ type: 'text', name: 'doctor_name', nullable: true })
  doctorName: string | null;

  @Column({ type: 'text', name: 'prescription_code', nullable: true })
  prescriptionCode: string | null;

  @Column({ type: 'text', name: 'image_prescription_url', nullable: true })
  imagePrescriptionUrl: string | null;

  @Column({ type: 'date', name: 'start_date' })
  startDate: string;

  @Column({ type: 'date', name: 'end_date', nullable: true })
  endDate: string | null;

  @Column({ type: 'boolean', name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => PrescriptionItem, (item) => item.prescription)
  items: PrescriptionItem[];
}