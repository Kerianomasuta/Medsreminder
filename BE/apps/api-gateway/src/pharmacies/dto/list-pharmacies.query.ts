import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';

export class ListPharmaciesQueryDto {
  @ApiPropertyOptional({
    deprecated: true,
    description:
      'Legacy compatibility flag. Pharmacy availability is no longer filtered by this field.',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === 'true' || value === true) return true;
    if (value === 'false' || value === false) return false;
    return value;
  })
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === undefined ? undefined : Number(value)))
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => (value === undefined ? undefined : Number(value)))
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @ApiPropertyOptional({
    description: 'Geohash calculated by the client for its current location',
  })
  @IsOptional()
  @IsString()
  @Matches(/^[0-9bcdefghjkmnpqrstuvwxyz]{4,12}$/)
  geohash?: string;

  @ApiPropertyOptional({ default: 10, maximum: 10 })
  @IsOptional()
  @Transform(({ value }) => (value === undefined ? undefined : Number(value)))
  @IsNumber()
  @Min(0.1)
  @Max(10)
  radiusKm?: number;
}
