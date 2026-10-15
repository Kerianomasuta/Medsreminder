import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

export class CheckoutPremiumDto {
  @ApiProperty({ enum: ['MONTH', 'YEAR'], example: 'MONTH', description: 'MONTH is 49000 VND. YEAR is 470400 VND, 20 percent off twelve months.' })
  @IsIn(['MONTH', 'YEAR'])
  plan: 'MONTH' | 'YEAR';
}
