import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsInt, IsNumber, IsUUID, Min, ValidateNested } from 'class-validator';

export class UpsertInventoryItemDto {
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

export class UpsertInventoryDto {
  @ApiProperty({ type: [UpsertInventoryItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => UpsertInventoryItemDto)
  items: UpsertInventoryItemDto[];
}
