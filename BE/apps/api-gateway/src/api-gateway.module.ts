import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'
import { AuthController } from './auth/auth.controller.js';
import { AuthService } from './auth/auth.service.js';
import { AuthModule } from './auth/auth.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/api-gateway/.env'
    }),

    AuthModule,
  ],
})
export class ApiGatewayModule {}
