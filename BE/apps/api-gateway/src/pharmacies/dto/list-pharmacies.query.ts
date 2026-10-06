import { ApiPropertyOptional } from '@nestjs/swagger';
<<<<<<< HEAD
import { Transform } from 'class-transformer';
import { IsBoolean, IsNumber, IsOptional, Max, Min } from 'class-validator';
=======
import { IsOptional, IsString, MaxLength } from 'class-validator';
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

export class ListPharmaciesQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
<<<<<<< HEAD
  @Transform(({ value }) => (value === undefined ? undefined : value === 'true' || value === true))
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
=======
  @IsString()
  @MaxLength(200)
  search?: string;
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
}
