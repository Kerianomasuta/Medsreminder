import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsNumber, IsOptional, IsUUID, Min } from 'class-validator';

export class CreateInventoryDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  medicineId: string;

  @ApiPropertyOptional({ example: 20, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  stockQuantity?: number;

  @ApiProperty({ example: 1500 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  pricePerUnit: number;
}

export class UpdateInventoryDto {
  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @IsInt()
  @Min(0)
  stockQuantity?: number;

  @ApiPropertyOptional({ example: 1500 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  pricePerUnit?: number;
}
