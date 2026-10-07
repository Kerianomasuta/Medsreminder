import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsMongoId, IsNumber, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

export class UpdatePharmacyDto {
  @ApiPropertyOptional({ example: '507f1f77bcf86cd799439013', description: 'MongoDB ObjectId of the pharmacist' })
  @IsOptional()
  @IsMongoId()
  pharmacistId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(150)
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(15)
  phoneNumber?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  addressText?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
