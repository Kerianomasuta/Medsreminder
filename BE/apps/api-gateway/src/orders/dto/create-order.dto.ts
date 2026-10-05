import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class CreateOrderItemDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  medicineId: string;

  @ApiProperty({ example: 2 })
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

  @ApiProperty({ type: [CreateOrderItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];
}
