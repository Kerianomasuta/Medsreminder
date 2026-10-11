import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsMongoId, IsOptional } from 'class-validator';

export class ListScheduleRulesQueryDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011', description: 'MongoDB ObjectId of the patient' })
  @IsMongoId()
  patientId: string;

  @ApiPropertyOptional({ enum: ['true', 'false'] })
  @IsOptional()
  @IsIn(['true', 'false'])
  isActive?: 'true' | 'false';
}
