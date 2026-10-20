import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsMongoId, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

function emptyToUndefined(value: unknown) {
  if (typeof value !== 'string') {
    return value;
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

export class ScanPrescriptionDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  patientId: string;

  @ApiPropertyOptional({
    example: '507f1f77bcf86cd799439012',
    description: 'Defaults to the signed-in user when omitted.',
  })
  @IsOptional()
  @Transform(({ value }) => emptyToUndefined(value))
  @IsMongoId()
  createdByCgId?: string;

  @ApiPropertyOptional({ example: '2026-10-01', description: 'Used when the photo has no start date' })
  @IsOptional()
  @Transform(({ value }) => emptyToUndefined(value))
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  startDate?: string;

  @ApiPropertyOptional({ example: '2026-10-31' })
  @IsOptional()
  @Transform(({ value }) => emptyToUndefined(value))
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  endDate?: string;

  @ApiPropertyOptional({ description: 'Ignored. Send the photo in the image file field.' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  imagePrescriptionUrl?: string;
}
