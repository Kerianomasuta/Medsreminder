import { ApiHideProperty, ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsISO8601, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class ListMedicationLogsQueryDto {
  @ApiPropertyOptional({
    example: '2026-10-08',
    description: 'First calendar day to include, Asia/Ho_Chi_Minh. Defaults to today. Doses scheduled before this day are omitted.',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  from?: string;

  @ApiPropertyOptional({
    example: '2026-10-08',
    description: 'Last calendar day to include, Asia/Ho_Chi_Minh, inclusive. Omit to include every upcoming dose after from.',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  to?: string;
}

export class RecordDoseDto {
  @ApiHideProperty()
  @IsOptional()
  @IsISO8601()
  @Matches(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,3})?)?(Z|[+-]\d{2}:\d{2})$/)
  actedAt?: string;
}

export class SnoozeDoseDto extends RecordDoseDto {
  @ApiProperty({ enum: [5, 10], example: 10, description: 'How many minutes to wait before the alarm rings again.' })
  @IsIn([5, 10])
  minutes: 5 | 10;
}

export class SkipDoseDto extends RecordDoseDto {
  @ApiPropertyOptional({ example: 'Buồn nôn', description: 'Optional reason, at most 500 characters.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  skipReason?: string;
}

export class DoseMedicineResponseDto {
  @ApiProperty({ example: 'Paracetamol' })
  name: string;

  @ApiPropertyOptional({ example: 'Acetaminophen', nullable: true })
  genericName: string | null;

  @ApiProperty({ enum: ['VIEN', 'GOI', 'CHAI'], example: 'VIEN' })
  unit: string;

  @ApiPropertyOptional({ example: 'https://example.com/paracetamol.png', nullable: true })
  imageUrl: string | null;
}

export class MedicationLogResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  scheduleRuleId: string;

  @ApiProperty({ example: '507f1f77bcf86cd799439011', description: 'MongoDB ObjectId of the patient' })
  patientId: string;

  @ApiProperty({ example: '2026-10-08T01:00:00.000Z', description: 'The original reminder instant.' })
  scheduledAt: Date;

  @ApiPropertyOptional({ example: '2026-10-08T01:05:00.000Z', nullable: true, description: 'Set only when the dose is TAKEN.' })
  actualTakenAt: Date | null;

  @ApiProperty({
    enum: ['SCHEDULED', 'SNOOZED', 'TAKEN', 'SKIPPED', 'MISSED'],
    example: 'SCHEDULED',
    description: 'SCHEDULED is waiting. SNOOZED is postponed. TAKEN, SKIPPED, and MISSED are final.',
  })
  status: string;

  @ApiPropertyOptional({ example: '2026-10-08T01:10:00.000Z', nullable: true, description: 'When a snoozed alarm should ring. Empty unless status is SNOOZED.' })
  snoozeUntil: Date | null;

  @ApiProperty({ example: 0, description: '0 before a skip or a miss. 1 after SKIPPED or MISSED.' })
  escalationLevel: number;

  @ApiPropertyOptional({ example: 'Buồn nôn', nullable: true })
  skipReason: string | null;

  @ApiPropertyOptional({ example: 2, nullable: true })
  dosagePerTime: number | null;

  @ApiPropertyOptional({ example: 'Sau ăn', nullable: true })
  instructions: string | null;

  @ApiPropertyOptional({ type: DoseMedicineResponseDto, nullable: true })
  medicine: DoseMedicineResponseDto | null;
}
