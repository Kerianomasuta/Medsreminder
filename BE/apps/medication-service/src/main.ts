import { NestFactory } from '@nestjs/core';
import { MedicationServiceModule } from './medication-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(MedicationServiceModule);
  await app.listen(process.env.port ?? 3000);
}
await bootstrap();
