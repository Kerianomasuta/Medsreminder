import { NestFactory } from '@nestjs/core';
import { ApiGatewayModule } from './api-gateway.module.js';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(ApiGatewayModule);

  const configService = app.get(ConfigService);

  const port = configService.get<number>('GATEWAY_PORT') || 3000

  await app.listen(port);
  console.log(`API GATEWAY is running at port: ${port}`);
}
await bootstrap();
