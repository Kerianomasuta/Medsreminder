import { Test, TestingModule } from '@nestjs/testing';
import { MedicationServiceController } from './medication-service.controller.js';
import { MedicationServiceService } from './medication-service.service.js';

describe('MedicationServiceController', () => {
  let medicationServiceController: MedicationServiceController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [MedicationServiceController],
      providers: [MedicationServiceService],
    }).compile();

    medicationServiceController = app.get<MedicationServiceController>(MedicationServiceController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(medicationServiceController.getHello()).toBe('Hello World!');
    });
  });
});
