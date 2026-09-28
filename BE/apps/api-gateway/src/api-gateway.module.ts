import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/api-gateway/.env'
    }),
  ],
  controllers: [],
  providers: [],
})
export class ApiGatewayModule {}
