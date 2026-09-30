import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsInt, IsOptional, Matches, Max, Min } from 'class-validator';

export class CreateScheduleRuleDto {
  @ApiProperty({ example: '20:00' })
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'reminderTime must be HH:mm' })
  reminderTime: string;

  @ApiPropertyOptional({ example: [1, 2, 3, 4, 5, 6, 7], description: '1 = Monday through 7 = Sunday' })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  daysOfWeek?: number[];
}
