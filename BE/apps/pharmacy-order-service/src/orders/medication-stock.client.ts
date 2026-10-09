import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';

export type ReplenishItem = {
  prescriptionItemId: string;
  quantity: number;
};

@Injectable()
export class MedicationStockClient {
  constructor(
    @Inject('MEDICATION_SERVICE')
    private readonly medicationClient: ClientProxy,
  ) {}

  replenish(items: ReplenishItem[]) {
    return lastValueFrom(
      this.medicationClient.send(
        { cmd: 'replenish_prescription_stock' },
        { items },
      ),
    );
  }
}
