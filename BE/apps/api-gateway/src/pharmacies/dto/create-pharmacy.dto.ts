import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
<<<<<<< HEAD
import { IsBoolean, IsNumber, IsOptional, IsString, IsUUID, Max, MaxLength, Min, MinLength } from 'class-validator';
=======
import { IsBoolean, IsLatitude, IsLongitude, IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

export class CreatePharmacyDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  pharmacistId: string;

  @ApiProperty({ example: 'Nhà thuốc An Khang' })
  @IsString()
<<<<<<< HEAD
  @MinLength(1)
  @MaxLength(150)
=======
  @IsNotEmpty()
  @MaxLength(200)
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
  name: string;

  @ApiProperty({ example: '0901234567' })
  @IsString()
<<<<<<< HEAD
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
=======
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
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
