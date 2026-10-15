import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class UpdateAdminUserDto {
  @ApiPropertyOptional({ example: 'Nguyen Van A' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  fullName?: string;

  @ApiPropertyOptional({ example: '0912345678' })
  @IsOptional()
  @Matches(/^0[235789][0-9]{8}$/, { message: 'please provide Vietnam phone number' })
  phone?: string;

  @ApiPropertyOptional({ enum: ['PATIENT', 'CARE_GIVER', 'PHARMACIST', 'ADMIN'] })
  @IsOptional()
  @IsIn(['PATIENT', 'CARE_GIVER', 'PHARMACIST', 'ADMIN'])
  role?: string;

  @ApiPropertyOptional({ description: 'false locks the account. A locked account cannot sign in.' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
