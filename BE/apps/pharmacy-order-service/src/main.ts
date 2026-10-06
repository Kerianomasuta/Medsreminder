import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { PharmacyOrderServiceModule } from './pharmacy-order-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(PharmacyOrderServiceModule);
  const configService = app.get(ConfigService);

<<<<<<< HEAD
  const host = configService.get<string>('PHARMACY_ORDER_SERVICE_HOST');
  const port = configService.get<number>('PHARMACY_ORDER_SERVICE_PORT');
=======
  const host = configService.get<string>('PHARMACY_SERVICE_HOST');
  const port = configService.get<number>('PHARMACY_SERVICE_PORT');
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.TCP,
    options: {
      host,
      port,
    },
  });

  await app.startAllMicroservices();
  console.log(`PHARMACY ORDER SERVICE is listening TCP at ${host}:${port}`);
}
await bootstrap();
