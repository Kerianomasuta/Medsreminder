import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsUUID } from 'class-validator';

export class ListScheduleRulesQueryDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  patientId: string;

  @ApiPropertyOptional({ enum: ['true', 'false'] })
  @IsOptional()
  @IsIn(['true', 'false'])
  isActive?: 'true' | 'false';
}
