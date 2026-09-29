import { Injectable } from '@nestjs/common';

@Injectable()
export class MedicationServiceService {
  getHello(): string {
    return 'Hello World!';
  }
}
