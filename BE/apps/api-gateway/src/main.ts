import { NestFactory } from '@nestjs/core';
import { ApiGatewayModule } from './api-gateway.module.js';
import { ConfigService } from '@nestjs/config';
import cookieParser from 'cookie-parser';
import { json, urlencoded } from 'express';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { RpcExceptionFilter } from './filter/rpc-exception.filter.js';

async function bootstrap() {
  const app = await NestFactory.create(ApiGatewayModule, { bodyParser: false });
  app.use(json({ limit: '1gb' }));
  app.use(urlencoded({ extended: true, limit: '1gb' }));
  const configService = app.get(ConfigService);
  const configuredCorsOrigins = (configService.get<string>('CORS_ORIGINS') ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  app.use(cookieParser())

  app.enableCors({
    origin: [
      /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/,
      'https://medsreminder.duckdns.org',
      'https://medsreminder.vercel.app',
      /^https:\/\/.*\.vercel\.app$/,
      ...configuredCorsOrigins,
    ],
    credentials: true
  })

  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }))

  app.useGlobalFilters(new RpcExceptionFilter())

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Meds Reminder API')
    .setDescription('API documentation for the Meds Reminder gateway')
    .setVersion('1.0')
    .addCookieAuth('accessToken')
    .addCookieAuth('refreshToken')
    .build();

  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, swaggerDocument);

  const port = configService.get<number>('GATEWAY_PORT') || 3000

  await app.listen(port);
  console.log(`API GATEWAY is running at port: ${port}`);
}
await bootstrap();
