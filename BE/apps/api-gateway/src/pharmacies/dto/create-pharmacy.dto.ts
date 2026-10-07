import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsMongoId, IsNumber, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

export class CreatePharmacyDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439013', description: 'MongoDB ObjectId of the pharmacist' })
  @IsMongoId()
  pharmacistId: string;

  @ApiProperty({ example: 'Nhà thuốc An Khang' })
  @IsString()
  @MinLength(1)
  @MaxLength(150)
  name: string;

  @ApiProperty({ example: '0901234567' })
  @IsString()
  @MinLength(1)
  @MaxLength(15)
  phoneNumber: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  addressText: string;

  @ApiProperty({ example: 10.7769 })
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({ example: 106.7009 })
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
