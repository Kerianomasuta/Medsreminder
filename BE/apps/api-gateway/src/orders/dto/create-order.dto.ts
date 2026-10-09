import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class CreateOrderItemDto {
  @ApiProperty({
    format: 'uuid',
    description:
      'Prescription line to buy. The pharmacy reviews the name stored on that line.',
  })
  @IsUUID()
  prescriptionItemId: string;

  @ApiProperty({ example: 30 })
  @IsInt()
  @Min(1)
  quantity: number;
}

export class CreateOrderDto {
  @ApiProperty({
    example: '507f1f77bcf86cd799439011',
    description: 'MongoDB ObjectId of the patient',
  })
  @IsMongoId()
  patientId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  pharmacyId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  prescriptionId: string;

  @ApiProperty({ enum: ['PICKUP', 'DELIVERY'] })
  @IsIn(['PICKUP', 'DELIVERY'])
  fulfillmentType: 'PICKUP' | 'DELIVERY';

  @ApiPropertyOptional({
    description:
      'Who receives the medicine. Optional for PICKUP, required for DELIVERY.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  recipientName?: string;

  @ApiPropertyOptional({
    description:
      'Phone of the person who receives the medicine. Optional for PICKUP, required for DELIVERY.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  recipientPhone?: string;

  @ApiPropertyOptional({
    description: 'Required for DELIVERY. Omit this field for PICKUP.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  deliveryAddress?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  patientNote?: string;

  @ApiProperty({ type: [CreateOrderItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];
}

export class ListMyOrdersQueryDto {
  @ApiPropertyOptional({
    enum: [
      'PENDING_REVIEW',
      'PREPARING',
      'READY_FOR_PICKUP',
      'SHIPPED',
      'COMPLETED',
      'CANCELLED',
    ],
  })
  @IsOptional()
  @IsIn([
    'PENDING_REVIEW',
    'PREPARING',
    'READY_FOR_PICKUP',
    'SHIPPED',
    'COMPLETED',
    'CANCELLED',
  ])
  status?: string;
}

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

  @ApiPropertyOptional({
    enum: [
      'PENDING_REVIEW',
      'PREPARING',
      'READY_FOR_PICKUP',
      'SHIPPED',
      'COMPLETED',
      'CANCELLED',
    ],
  })
  @IsOptional()
  @IsIn([
    'PENDING_REVIEW',
    'PREPARING',
    'READY_FOR_PICKUP',
    'SHIPPED',
    'COMPLETED',
    'CANCELLED',
  ])
  status?: string;
}

export class ShipOrderDto {
  @ApiProperty({ example: 'Nguyen Van Giao' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  shipperName: string;

  @ApiProperty({ example: '0901234567' })
  @IsString()
  @MinLength(1)
  @MaxLength(15)
  shipperPhone: string;
}

export class RejectOrderDto {
  @ApiProperty({ example: 'Hết hàng' })
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  rejectionReason: string;
}

export class CancelOrderDto {
  @ApiProperty({ example: 'Không tới lấy' })
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  rejectionReason: string;
}
