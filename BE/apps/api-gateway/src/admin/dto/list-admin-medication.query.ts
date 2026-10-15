import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsMongoId, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';

const DAY = /^\d{4}-\d{2}-\d{2}$/;

export function emptyToUndefined({ value }: { value: unknown }) {
  if (typeof value === 'string' && value.trim() === '') {
    return undefined;
  }
  return value;
}

export function queryBoolean({ value }: { value: unknown }) {
  if (value === true || value === 'true') {
    return true;
  }
  if (value === false || value === 'false') {
    return false;
  }
  return value;
}

export class ListAdminPrescriptionsQueryDto {
  @ApiPropertyOptional({ description: 'Mongo id of the patient.' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsMongoId()
  patientId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(queryBoolean)
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({ description: 'Search title, doctor name, or prescription code.' })
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

export class ListAdminLogsQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsMongoId()
  patientId?: string;

  @ApiPropertyOptional({ enum: ['SCHEDULED', 'TAKEN', 'SNOOZED', 'MISSED', 'SKIPPED'] })
  @IsOptional()
  @Transform(emptyToUndefined)
  @IsIn(['SCHEDULED', 'TAKEN', 'SNOOZED', 'MISSED', 'SKIPPED'])
  status?: string;

  @ApiPropertyOptional({ example: '2026-10-01', description: 'First scheduled day in Asia/Ho_Chi_Minh, inclusive.' })
  @IsOptional()
  @Transform(emptyToUndefined)
  @Matches(DAY)
  from?: string;

  @ApiPropertyOptional({ example: '2026-10-15', description: 'Last scheduled day in Asia/Ho_Chi_Minh, inclusive.' })
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
