import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsMongoId, IsOptional, IsString, IsUUID, Matches, Max, MaxLength, Min } from 'class-validator';
import { emptyToUndefined } from './list-admin-medication.query.js';

const DAY = /^\d{4}-\d{2}-\d{2}$/;
const ORDER_STATUSES = ['PENDING_REVIEW', 'PREPARING', 'READY_FOR_PICKUP', 'SHIPPED', 'COMPLETED', 'CANCELLED'];

export class ListAdminPharmaciesQueryDto {
  @ApiPropertyOptional({ description: 'Search pharmacy name, phone, or address.' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsString()
  @MaxLength(80)
  q?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 20, maximum: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}

export class ListAdminOrdersQueryDto {
  @ApiPropertyOptional({ enum: ORDER_STATUSES })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsIn(ORDER_STATUSES)
  status?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsUUID()
  pharmacyId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsMongoId()
  patientId?: string;

  @ApiPropertyOptional({ description: 'Search the order code.' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsString()
  @MaxLength(80)
  q?: string;

  @ApiPropertyOptional({ example: '2026-10-01' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @Matches(DAY)
  from?: string;

  @ApiPropertyOptional({ example: '2026-10-15' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @Matches(DAY)
  to?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 20, maximum: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}
