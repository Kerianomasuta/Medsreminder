import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsMongoId, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class ScanPrescriptionDto {
  @ApiProperty({ description: 'Public URL of the paper prescription photo' })
  @IsString()
  @MaxLength(2000)
  @Matches(/^https?:\/\//i, { message: 'imagePrescriptionUrl must be an http or https URL' })
  imagePrescriptionUrl: string;

  @ApiProperty({ example: '507f1f77bcf86cd799439011' })
  @IsMongoId()
  patientId: string;

  @ApiProperty({ example: '507f1f77bcf86cd799439012' })
  @IsMongoId()
  createdByCgId: string;

  @ApiPropertyOptional({ example: '2026-10-01', description: 'Used when the photo has no start date' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  startDate?: string;

  @ApiPropertyOptional({ example: '2026-10-31' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  endDate?: string;
}
