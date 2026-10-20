import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { AiServiceModule } from './ai-service.module.js';
import { RpcErrorFilter } from './rpc-error.filter.js';

async function bootstrap() {
  const app = await NestFactory.create(AiServiceModule);
  app.useGlobalFilters(new RpcErrorFilter());
  const configService = app.get(ConfigService);

  const host = configService.get<string>('AI_SERVICE_HOST');
  const port = configService.get<number>('AI_SERVICE_PORT');

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.TCP,
    options: {
      host,
      port,
    },
  });

  await app.startAllMicroservices();
  console.log(`AI SERVICE is listening TCP at ${host}:${port}`);
}
await bootstrap();
