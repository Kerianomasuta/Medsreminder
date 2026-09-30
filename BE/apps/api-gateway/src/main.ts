import { NestFactory } from '@nestjs/core';
import { ApiGatewayModule } from './api-gateway.module.js';
import { ConfigService } from '@nestjs/config';
import cookieParser from 'cookie-parser';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(ApiGatewayModule);

  app.use(cookieParser())

  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
  }))

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Meds Reminder API')
    .setDescription('API documentation for the Meds Reminder gateway')
    .setVersion('1.0')
    .addCookieAuth('accessToken')
    .addCookieAuth('refreshToken')
    .build();

  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, swaggerDocument);

  const configService = app.get(ConfigService);

  const port = configService.get<number>('GATEWAY_PORT') || 3000

  await app.listen(port);
  console.log(`API GATEWAY is running at port: ${port}`);
}
await bootstrap();
