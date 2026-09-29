import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { DoseStatus } from '../../enums/dose-status.enum.js';
import { ScheduleRule } from '../../schedule-rules/schema/schedule-rule.entity.js';

@Entity({ schema: 'medication', name: 'medication_logs' })
@Index('medication_logs_escalation_idx', ['status', 'scheduledAt', 'escalationLevel'])
@Index('medication_logs_patient_scheduled_idx', ['patientId', 'scheduledAt'])
export class MedicationLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'schedule_rule_id' })
  scheduleRuleId: string;

  @Column({ type: 'uuid', name: 'patient_id' })
  patientId: string;

  @Column({ type: 'timestamptz', name: 'scheduled_at' })
  scheduledAt: Date;

  @Column({ type: 'timestamptz', name: 'actual_taken_at', nullable: true })
  actualTakenAt: Date | null;

  @Column({ type: 'enum', enum: DoseStatus, enumName: 'dose_status', default: DoseStatus.SCHEDULED })
  status: DoseStatus;

  @Column({ type: 'timestamptz', name: 'snooze_until', nullable: true })
  snoozeUntil: Date | null;

  @Column({ type: 'smallint', name: 'escalation_level', default: 0 })
  escalationLevel: number;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => ScheduleRule, (rule) => rule.logs, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'schedule_rule_id' })
  scheduleRule: ScheduleRule;
}