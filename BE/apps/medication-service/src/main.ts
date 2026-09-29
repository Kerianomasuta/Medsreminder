import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { MedicationServiceModule } from './medication-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(MedicationServiceModule);
  const configService = app.get(ConfigService);

  const host = configService.get<string>('MEDICATION_SERVICE_HOST');
  const port = configService.get<number>('MEDICATION_SERVICE_PORT');

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.TCP,
    options: {
      host,
      port,
    },
  });

  await app.startAllMicroservices();
  console.log(`MEDICATION SERVICE is listening TCP at ${host}:${port}`);
}
await bootstrap();
