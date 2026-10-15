import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class SaveFcmTokenDto {
  @ApiProperty({ description: 'Firebase Cloud Messaging token for this device' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  token: string;
}
