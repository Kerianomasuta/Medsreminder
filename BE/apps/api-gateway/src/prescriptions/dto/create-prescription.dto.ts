import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class CreateScheduleDto {
  @ApiProperty({ example: '08:00' })
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'reminderTime must be HH:mm' })
  reminderTime: string;

  @ApiPropertyOptional({ example: [1, 2, 3, 4, 5, 6, 7], description: '1 = Monday through 7 = Sunday' })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  daysOfWeek?: number[];
}

export class CreatePrescriptionItemDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  medicineId: string;

  @ApiProperty({ example: 2 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  dosagePerTime: number;

  @ApiPropertyOptional({ example: 30, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  currentStock?: number;

  @ApiPropertyOptional({ example: 6, default: 6 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reorderThreshold?: number;

  @ApiPropertyOptional({ example: 'Sau ăn' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  instructions?: string;

  @ApiProperty({ type: [CreateScheduleDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateScheduleDto)
  schedules: CreateScheduleDto[];
}

export class CreatePrescriptionDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  patientId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  createdByCgId: string;

  @ApiProperty({ example: 'Đơn tháng 10' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  title: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  doctorName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  prescriptionCode?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  imagePrescriptionUrl?: string;

  @ApiProperty({ example: '2026-10-01' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  startDate: string;

  @ApiPropertyOptional({ example: '2026-10-31' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  endDate?: string;

  @ApiProperty({ type: [CreatePrescriptionItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreatePrescriptionItemDto)
  items: CreatePrescriptionItemDto[];
}
