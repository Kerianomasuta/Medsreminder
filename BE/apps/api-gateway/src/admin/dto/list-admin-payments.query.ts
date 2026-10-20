import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsMongoId, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';
import { emptyToUndefined } from './list-admin-medication.query.js';

const DAY = /^\d{4}-\d{2}-\d{2}$/;

export class ListAdminPaymentsQueryDto {
  @ApiPropertyOptional({ enum: ['PENDING', 'PAID', 'FAILED'] })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsIn(['PENDING', 'PAID', 'FAILED'])
  status?: string;

  @ApiPropertyOptional({ enum: ['MONTH', 'YEAR'] })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsIn(['MONTH', 'YEAR'])
  plan?: string;

  @ApiPropertyOptional({ description: 'Mongo id of the paying account.' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsMongoId()
  userId?: string;

  @ApiPropertyOptional({ description: 'Search the payment reference or provider transaction number.' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsString()
  @MaxLength(80)
  q?: string;

  @ApiPropertyOptional({ example: '2026-10-01', description: 'First created day in Asia/Ho_Chi_Minh, inclusive.' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @Matches(DAY)
  from?: string;

  @ApiPropertyOptional({ example: '2026-10-15', description: 'Last created day in Asia/Ho_Chi_Minh, inclusive.' })
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
