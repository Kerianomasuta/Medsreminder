import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PrescriptionScheduleResponseDto {
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
}

export class PrescriptionItemResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  prescriptionId: string;

  @ApiProperty({ example: 'Paracetamol' })
  name: string;

  @ApiPropertyOptional({ example: 'Acetaminophen', nullable: true })
  genericName: string | null;

  @ApiProperty({ enum: ['VIEN', 'GOI', 'CHAI'], example: 'VIEN' })
  unit: string;

  @ApiPropertyOptional({ example: 'https://example.com/paracetamol.png', nullable: true })
  imageUrl: string | null;

  @ApiProperty({ example: 2 })
  dosagePerTime: number;

  @ApiProperty({ example: 30 })
  currentStock: number;

  @ApiProperty({ example: 6 })
  reorderThreshold: number;

  @ApiPropertyOptional({ example: 'Sau ăn', nullable: true })
  instructions: string | null;

  @ApiProperty({ type: [PrescriptionScheduleResponseDto] })
  schedules: PrescriptionScheduleResponseDto[];
}

export class PrescriptionResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  patientId: string;

  @ApiProperty({ format: 'uuid' })
  createdByCgId: string;

  @ApiProperty({ example: 'Đơn tháng 10' })
  title: string;

  @ApiPropertyOptional({ example: 'Nguyen Van A', nullable: true })
  doctorName: string | null;

  @ApiPropertyOptional({ example: 'RX-1001', nullable: true })
  prescriptionCode: string | null;

  @ApiPropertyOptional({ nullable: true })
  imagePrescriptionUrl: string | null;

  @ApiProperty({ example: '2026-10-01' })
  startDate: string;

  @ApiPropertyOptional({ example: '2026-10-31', nullable: true })
  endDate: string | null;

  @ApiProperty({ example: true })
  isActive: boolean;

  @ApiProperty({ example: '2026-10-01T00:00:00.000Z' })
  createdAt: string;

  @ApiProperty({ example: '2026-10-01T00:00:00.000Z' })
  updatedAt: string;

  @ApiProperty({ type: [PrescriptionItemResponseDto] })
  items: PrescriptionItemResponseDto[];
}
