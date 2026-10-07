import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class CreateOrderItemDto {
  @ApiProperty({ format: 'uuid', description: 'Prescription line to buy. The pharmacy reviews the name stored on that line.' })
  @IsUUID()
  prescriptionItemId: string;

  @ApiProperty({ example: 30 })
  @IsInt()
  @Min(1)
  quantity: number;
}

export class CreateOrderDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  patientId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  caregiverId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  pharmacyId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  prescriptionId: string;

  @ApiProperty({ enum: ['PICKUP', 'DELIVERY'] })
  @IsIn(['PICKUP', 'DELIVERY'])
  fulfillmentType: 'PICKUP' | 'DELIVERY';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  recipientName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(15)
  recipientPhone?: string;

  @ApiPropertyOptional()
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

export class ListOrdersQueryDto {
  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  patientId?: string;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  caregiverId?: string;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  pharmacyId?: string;

  @ApiPropertyOptional({ enum: ['PENDING_REVIEW', 'PREPARING', 'READY_FOR_PICKUP', 'SHIPPED', 'COMPLETED', 'CANCELLED'] })
  @IsOptional()
  @IsIn(['PENDING_REVIEW', 'PREPARING', 'READY_FOR_PICKUP', 'SHIPPED', 'COMPLETED', 'CANCELLED'])
  status?: string;
}

export class ShipOrderDto {
  @ApiPropertyOptional({ example: 'GrabExpress' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  shippingCarrier?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(255)
  trackingCodeOrLink?: string;
}

export class RejectOrderDto {
  @ApiProperty({ example: 'Hết hàng' })
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  rejectionReason: string;
}

export class CancelOrderDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  rejectionReason: string;

  @ApiProperty({ enum: ['CAREGIVER', 'PHARMACIST'] })
  @IsIn(['CAREGIVER', 'PHARMACIST'])
  actor: 'CAREGIVER' | 'PHARMACIST';
}
