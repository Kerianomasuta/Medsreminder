import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsLatitude, IsLongitude, IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreatePharmacyDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  pharmacistId: string;

  @ApiProperty({ example: 'Nhà thuốc An Khang' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name: string;

  @ApiProperty({ example: '0901234567' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  phone: string;

  @ApiProperty({ example: '12 Nguyễn Huệ, Quận 1' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  addressText: string;

  @ApiProperty({ example: 10.776889 })
  @IsLatitude()
  latitude: number;

  @ApiProperty({ example: 106.700806 })
  @IsLongitude()
  longitude: number;
}

export class UpdatePharmacyDto {
  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  pharmacistId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  phone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  addressText?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsLatitude()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsLongitude()
  longitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
