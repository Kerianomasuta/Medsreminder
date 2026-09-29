import { Global, Module } from '@nestjs/common'
import { ConfigModule, ConfigService } from '@nestjs/config'
import { ErrorHandling } from '../../../libs/error-handling/src/error-handling.js'
import { Redis } from 'ioredis'

@Global()
@Module({
    imports: [ConfigModule],
    providers: [
        {
            provide: 'REDIS_CLIENT',
            inject: [ConfigService],
            useFactory: (configService: ConfigService) => {
                const redisUrl = configService.get<string>('UPSTASH_REDIS_URL')
                if (!redisUrl) {
                    throw ErrorHandling.InternalServerError(`Cannot configure redis url`)
                }
                return new Redis(redisUrl)
            },
        }
    ],
    exports: ['REDIS_CLIENT']
})

export class RedisModule {}