import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { toRpcHttpException } from '../rpc-http-exception.js';

@Injectable()
export class BillingService {
  constructor(
    @Inject('USER_SERVICE')
    private readonly userClient: ClientProxy,
  ) {}

  plans() {
    return this.send({ cmd: 'handle_list_premium_plans' }, {});
  }

  config() {
    return this.send({ cmd: 'handle_billing_config' }, {});
  }

  createPaymentLink(userId: string, plan: 'MONTH' | 'YEAR') {
    return this.send({ cmd: 'handle_create_payment_link' }, { userId, plan });
  }

  confirmPayos(body: unknown) {
    return this.send({ cmd: 'handle_payos_webhook' }, { body });
  }

  private async send<T>(pattern: { cmd: string }, payload: unknown): Promise<T> {
    try {
      return await lastValueFrom(this.userClient.send<T>(pattern, payload));
    } catch (error) {
      throw toRpcHttpException(error, 'User service is unavailable');
    }
  }
}
