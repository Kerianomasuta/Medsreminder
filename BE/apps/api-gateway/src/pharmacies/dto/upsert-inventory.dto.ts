import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsNumber, IsUUID, Min } from 'class-validator';

export class UpsertInventoryDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  medicineId: string;

  @ApiProperty({ example: 40 })
  @IsInt()
  @Min(0)
  stockQuantity: number;

  @ApiProperty({ example: 12000 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  pricePerUnit: number;
}
