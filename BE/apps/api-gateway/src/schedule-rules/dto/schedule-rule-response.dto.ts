import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ScheduleMedicineResponseDto {
  @ApiProperty({ example: 'Paracetamol' })
  name: string;

  @ApiPropertyOptional({ example: 'Acetaminophen', nullable: true })
  genericName: string | null;

  @ApiProperty({ enum: ['VIEN', 'GOI', 'CHAI'], example: 'VIEN' })
  unit: string;

  @ApiPropertyOptional({ example: 'https://example.com/paracetamol.png', nullable: true })
  imageUrl: string | null;
}

export class SchedulePrescriptionResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ example: 'Đơn tháng 10' })
  title: string;

  @ApiProperty({ example: '2026-10-01' })
  startDate: string;

  @ApiPropertyOptional({ example: '2026-10-31', nullable: true })
  endDate: string | null;

  @ApiProperty({ example: true })
  isActive: boolean;
}

export class ScheduleRuleResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  prescriptionItemId: string;

  @ApiProperty({ format: 'uuid' })
  patientId: string;

  @ApiProperty({ example: '08:00:00', description: 'Stored as HH:mm:ss' })
  reminderTime: string;

  @ApiProperty({ example: [1, 2, 3, 4, 5, 6, 7], description: '1 = Monday through 7 = Sunday' })
  daysOfWeek: number[];

  @ApiProperty({ example: true })
  isActive: boolean;

  @ApiProperty({ example: 2 })
  dosagePerTime: number;

  @ApiPropertyOptional({ example: 'Sau ăn', nullable: true })
  instructions: string | null;

  @ApiProperty({ type: ScheduleMedicineResponseDto })
  medicine: ScheduleMedicineResponseDto;

  @ApiProperty({ type: SchedulePrescriptionResponseDto })
  prescription: SchedulePrescriptionResponseDto;
}
