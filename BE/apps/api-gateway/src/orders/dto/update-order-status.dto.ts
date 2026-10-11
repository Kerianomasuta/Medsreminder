import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsIn,
  IsMongoId,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { ORDER_STATUSES } from './list-orders.query.js';

export class UpdateOrderStatusDto {
  @ApiProperty({ enum: ORDER_STATUSES })
  @IsIn(ORDER_STATUSES)
  status: (typeof ORDER_STATUSES)[number];

  @ApiPropertyOptional({
    example: '507f1f77bcf86cd799439014',
    description: 'MongoDB ObjectId of the shipper',
  })
  @IsOptional()
  @IsMongoId()
  shipperId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(500)
  rejectionReason?: string;

  @ApiPropertyOptional({ example: '1234' })
  @IsOptional()
  @Matches(/^\d{4}$/)
  otpCode?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  podImageUrl?: string;
}
