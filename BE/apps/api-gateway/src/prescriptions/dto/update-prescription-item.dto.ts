import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsInt, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

const MEDICINE_UNITS = ['VIEN', 'GOI', 'CHAI'] as const;

export class UpdatePrescriptionItemDto {
  @ApiPropertyOptional({ example: 'Paracetamol' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  name?: string;

  @ApiPropertyOptional({ example: 'Acetaminophen' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  genericName?: string | null;

  @ApiPropertyOptional({ enum: MEDICINE_UNITS, example: 'VIEN' })
  @IsOptional()
  @IsIn(MEDICINE_UNITS)
  unit?: (typeof MEDICINE_UNITS)[number];

  @ApiPropertyOptional({ example: 'https://example.com/paracetamol.png' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  imageUrl?: string | null;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  dosagePerTime?: number;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @IsInt()
  @Min(0)
  currentStock?: number;

  @ApiPropertyOptional({ example: 6 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reorderThreshold?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  instructions?: string | null;
}
