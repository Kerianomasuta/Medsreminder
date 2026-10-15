import { Body, Controller, Get, Post, Query, Req, UseGuards } from '@nestjs/common';
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
  @ApiOperation({ summary: 'Create a PayOS checkout link that opens the user bank app' })
  createPaymentLink(@Body() dto: CheckoutPremiumDto, @Req() request: Request) {
    const user = (request as Request & { user: AccessUser }).user;
    return this.billingService.createPaymentLink(user.userId, dto.plan);
  }

  @Post('payos-webhook')
  @ApiOperation({ summary: 'PayOS payment webhook. Activates premium after a verified transfer.' })
  payosWebhook(@Body() body: Record<string, unknown>) {
    return this.billingService.confirmPayos(body);
  }

  @Post('checkout')
  @ApiCookieAuth('accessToken')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Start a VNPay payment for premium' })
  checkout(@Body() dto: CheckoutPremiumDto, @Req() request: Request) {
    const user = (request as Request & { user: AccessUser }).user;
    return this.billingService.checkout(user.userId, dto.plan, clientIp(request));
  }

  @Get('vnpay/return')
  @ApiOperation({ summary: 'Browser return URL after VNPay. Activates premium when the payment succeeded.' })
  vnpayReturn(@Query() query: Request['query']) {
    return this.billingService.confirm(queryRecord(query));
  }

  @Get('vnpay/ipn')
  @ApiOperation({ summary: 'VNPay server callback. Returns only the VNPay response codes.' })
  async vnpayIpn(@Query() query: Request['query']) {
    const result = await this.billingService.confirm(queryRecord(query));
    return { RspCode: result.RspCode, Message: result.Message };
  }
}

function clientIp(request: Request) {
  const forwarded = request.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded;
  }
  return request.ip ?? '127.0.0.1';
}

function queryRecord(query: Request['query']) {
  const record: Record<string, string> = {};
  for (const [key, value] of Object.entries(query)) {
    if (typeof value === 'string') {
      record[key] = value;
    } else if (Array.isArray(value) && typeof value[0] === 'string') {
      record[key] = value[0];
    }
  }
  return record;
}
