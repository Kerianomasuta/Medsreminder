import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { MedicationLog } from '../../medication-logs/schema/medication-log.entity.js';
import { PrescriptionItem } from '../../prescriptions/schema/prescription-item.entity.js';

@Entity({ schema: 'medication', name: 'schedule_rules' })
@Index('schedule_rules_patient_idx', ['patientId', 'isActive'])
export class ScheduleRule {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'prescription_item_id' })
  prescriptionItemId: string;

  @Column({ type: 'varchar', length: 24, name: 'patient_id' })
  patientId: string;

  @Column({ type: 'time', name: 'reminder_time' })
  reminderTime: string;

  @Column({ type: 'smallint', array: true, name: 'days_of_week', default: [1, 2, 3, 4, 5, 6, 7] })
  daysOfWeek: number[];

  @Column({ type: 'boolean', name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => PrescriptionItem, (item) => item.scheduleRules, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'prescription_item_id' })
  prescriptionItem: PrescriptionItem;

  @OneToMany(() => MedicationLog, (log) => log.scheduleRule)
  logs: MedicationLog[];
}