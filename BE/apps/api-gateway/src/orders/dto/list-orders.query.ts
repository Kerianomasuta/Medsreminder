import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsMongoId, IsOptional, IsUUID } from 'class-validator';

export const ORDER_STATUSES = [
  'PENDING_REVIEW',
  'PREPARING',
  'READY_FOR_PICKUP',
  'ASSIGNED',
  'IN_TRANSIT',
  'DELIVERED',
  'CANCELLED',
] as const;

export class ListOrdersQueryDto {
  @ApiPropertyOptional({
    example: '507f1f77bcf86cd799439011',
    description: 'MongoDB ObjectId of the patient',
  })
  @IsOptional()
  @IsMongoId()
  patientId?: string;

  @ApiPropertyOptional({
    example: '507f1f77bcf86cd799439012',
    description: 'MongoDB ObjectId of the caregiver',
  })
  @IsOptional()
  @IsMongoId()
  caregiverId?: string;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  pharmacyId?: string;

  @ApiPropertyOptional({ enum: ORDER_STATUSES })
  @IsOptional()
  @IsIn(ORDER_STATUSES)
  status?: (typeof ORDER_STATUSES)[number];
}
