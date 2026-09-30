import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class ListMedicinesQueryDto {
  @ApiPropertyOptional({ description: 'Match medicine name or generic name' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  search?: string;
}
