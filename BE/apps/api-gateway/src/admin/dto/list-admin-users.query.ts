import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

const ROLES = ['PATIENT', 'CARE_GIVER', 'PHARMACIST', 'ADMIN'];

export class ListAdminUsersQueryDto {
  @ApiPropertyOptional({ enum: ROLES, description: 'Keep only this role.' })
  @IsOptional()
  @IsIn(ROLES)
  role?: string;

  @ApiPropertyOptional({ description: 'Search email, full name, or phone.' })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  q?: string;

  @ApiPropertyOptional({ description: 'true keeps open accounts. false keeps locked accounts.' })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true' ? true : value === false || value === 'false' ? false : value)
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 20, maximum: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}
