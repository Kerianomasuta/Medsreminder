import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class CheckoutPremiumDto {
  @ApiProperty({ enum: ['MONTH', 'YEAR'], example: 'MONTH', description: 'MONTH is 49000 VND. YEAR is 470400 VND, 20 percent off twelve months.' })
  @IsIn(['MONTH', 'YEAR'])
  plan: 'MONTH' | 'YEAR';

  @ApiPropertyOptional({ example: 'https://medsreminder.example/vip', description: 'Page PayOS opens after a successful payment.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  returnUrl?: string;

  @ApiPropertyOptional({ example: 'https://medsreminder.example/vip', description: 'Page PayOS opens when the payer presses Cancel.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  cancelUrl?: string;
}
