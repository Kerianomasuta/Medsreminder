import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class ListPrescriptionsQueryDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  patientId: string;
}
