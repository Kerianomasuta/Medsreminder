import { Body, Controller, Get, HttpCode, HttpStatus, Post, Req, UseGuards } from '@nestjs/common';
import { ApiCookieAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guards.js';
import { BillingService } from './billing.service.js';
import { CheckoutPremiumDto } from './dto/checkout-premium.dto.js';

type AccessUser = { userId: string };

@Controller('api/v1/billing')
@ApiTags('Billing')
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  @Get('config')
  @ApiOperation({ summary: 'Feature flag. False hides bank checkout while Google reviews the Play Store build.' })
  config() {
    return this.billingService.config();
  }

  @Get('plans')
  @ApiOperation({ summary: 'Premium prices: 49000 VND per month, 470400 VND per year' })
  plans() {
    return this.billingService.plans();
  }

  @Post('create-payment-link')
  @ApiCookieAuth('accessToken')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Create a PayOS checkout link. Rejects another plan while a paid VIP month is still active.' })
  createPaymentLink(@Body() dto: CheckoutPremiumDto, @Req() request: Request) {
    const user = (request as Request & { user: AccessUser }).user;
    return this.billingService.createPaymentLink(user.userId, dto.plan);
  }

  @Post('payos-webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'PayOS payment webhook. Activates premium after a verified transfer.' })
  payosWebhook(@Body() body: Record<string, unknown>) {
    return this.billingService.confirmPayos(body);
  }
}
