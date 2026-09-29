import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { UserModule } from './users/user.module.js';
import { RedisModule } from '../utils/redis.module.js'
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from './auth/auth.module.js';


@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/user-service/.env'
    }),

    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const uri = configService.get<string>('MONGO_URI');
        console.log(`Connecting to MongoDB...`);
        return {
          uri: uri,
          connectionFactory: async (connection) => {
            connection.on('connected', () => {
              console.log(`Connected to MongoDB successfully!`);
            })
            connection.on('error', () => {
              console.log(`Cannot connect to MongoDB server!`);
            })

            return connection
          }
        }
      }
    }),

    UserModule,
    AuthModule,
    RedisModule,
  ],
})
export class UserServiceModule {}
