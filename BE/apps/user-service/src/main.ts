import { NestFactory } from '@nestjs/core';
import { UserServiceModule } from './user-service.module.js';
import { ConfigService } from '@nestjs/config';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';

async function bootstrap() {
  const app = await NestFactory.create(UserServiceModule);

  const configService = app.get(ConfigService)

  const host = configService.get<string>('USER_SERVICE_HOST')
  const port = configService.get<number>('USER_SERVICE_PORT')

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.TCP,
    options: {
      host: host,
      port: port,
    },
  })

  // await app.listen(process.env.port ?? 3000);
  await app.startAllMicroservices()
  console.log(`USER SERVICE is listening TCP at ${host}:${port}`);
}
await bootstrap();
