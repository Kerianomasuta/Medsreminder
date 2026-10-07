import { ApiProperty } from '@nestjs/swagger';
import { IsMongoId } from 'class-validator';

export class ListPrescriptionsQueryDto {
  @ApiProperty({ example: '507f1f77bcf86cd799439011', description: 'MongoDB ObjectId of the patient' })
  @IsMongoId()
  patientId: string;
}
