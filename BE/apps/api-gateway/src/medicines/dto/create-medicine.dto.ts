import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export const MEDICINE_UNITS = ['VIEN', 'GOI', 'CHAI'] as const;

export class CreateMedicineDto {
  @ApiProperty({ example: 'Paracetamol' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name: string;

  @ApiPropertyOptional({ example: 'Acetaminophen' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  genericName?: string;

  @ApiProperty({ enum: MEDICINE_UNITS, example: 'VIEN' })
  @IsIn(MEDICINE_UNITS)
  unit: (typeof MEDICINE_UNITS)[number];

  @ApiPropertyOptional({ example: 'Uống sau ăn' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  instructionNote?: string;

  @ApiPropertyOptional({ example: 'https://example.com/paracetamol.png' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  imageUrl?: string;
}
