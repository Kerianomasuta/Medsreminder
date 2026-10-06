import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
<<<<<<< HEAD
  IsIn,
  IsInt,
  IsNumber,
=======
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
<<<<<<< HEAD
  MinLength,
=======
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  ValidateNested,
} from 'class-validator';

export class CreateOrderItemDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
<<<<<<< HEAD
  prescriptionItemId: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  medicineId: string;

  @ApiProperty({ example: 30 })
  @IsInt()
  @Min(1)
  quantity: number;

  @ApiProperty({ example: 12000 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  unitPrice: number;
=======
  medicineId: string;

  @ApiProperty({ example: 2 })
  @IsInt()
  @Min(1)
  quantity: number;
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
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

<<<<<<< HEAD
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
=======
  @ApiProperty({ example: '12 Nguyễn Huệ, Quận 1' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  deliveryAddress: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsLatitude()
  deliveryLat?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsLongitude()
  deliveryLng?: number;

  @ApiProperty({ example: '0901234567' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  recipientPhone: string;
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

  @ApiProperty({ type: [CreateOrderItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];
}
<<<<<<< HEAD

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
=======
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
