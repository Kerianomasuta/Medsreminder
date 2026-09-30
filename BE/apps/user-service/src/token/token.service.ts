import { Inject, Injectable } from "@nestjs/common";
import { Redis } from 'ioredis'
import { JwtService } from '@nestjs/jwt'
import { ConfigService } from "@nestjs/config";
import { ErrorHandling } from "@lib/error-handling";

const MAX_DEVICES = 2;
const TTL = 7 *24 * 60 * 60

@Injectable()
export class TokenService {
    constructor(
        @Inject('REDIS_CLIENT')
        private readonly redisClient: Redis,
        private readonly jwtService: JwtService,
        private readonly configService: ConfigService,
    ) {}

    async generateToken(input: {
        deviceId: string,
        userId: string,
        role: string,
        fullName: string,
    }) {
        const finalDeviceId = input.deviceId !== '' ? input.deviceId : `DEVICE_${crypto.randomUUID()}`

        const [accessToken, refreshToken] = await Promise.all([
            this.jwtService.signAsync(
                {
                    userId: input.userId,
                    deviceId: finalDeviceId,
                    fullName: input.fullName,
                    role: input.role,
                },
                {
                    secret: this.configService.get<string>('ACCESS_JWT_SECRET'),
                    expiresIn: '15m'
                }  
            ),

            this.jwtService.signAsync(
                {
                    userId: input.userId,
                    deviceId: finalDeviceId
                },
                {
                    secret: this.configService.get<string>('REFRESH_JWT_SECRET'),
                    expiresIn: '7d',
                }
            )
        ])

        return {
            accessToken,
            refreshToken,
            deviceId: finalDeviceId
        }
    }

    async saveRefreshToken(input: {
        refreshToken: string,
        deviceId: string,
        userId: string,
    }) {
        try {
            const refreshKey = `refresh_token:${input.userId}:${input.deviceId}`

            const userDevicesKey = `user_device:${input.userId}`

            await this.redisClient.lrem(userDevicesKey, 0, input.deviceId) //so 0 co nghia la xoa toan bo nhung key co deviceId giong

            //day vao lai mang de danh dau cai deviceId moi
            await this.redisClient.rpush(userDevicesKey, input.deviceId)

            //dem so luong device trong mang
            const deviceCount = await this.redisClient.llen(userDevicesKey)

            if (deviceCount > MAX_DEVICES) {
                //xoa phan tu dau trong mang tuc la device cu~ nhat
                const oldestDeviceId = await this.redisClient.lpop(userDevicesKey)

                if (oldestDeviceId) {
                    const oldestRefreshKey = `refresh_token:${input.userId}:${oldestDeviceId}`
                    await this.redisClient.del(oldestRefreshKey)
                }
            }

            await this.redisClient.set(
                refreshKey,
                input.refreshToken,
                'EX',
                TTL
            )

            await this.redisClient.expire(userDevicesKey, TTL)
        } catch (error) {
            console.log(`Redis Error, Cannot save refreshToken: ${error}`);
            throw ErrorHandling.ServiceUnavailableError(`Cannot save refreshToken now, please try again later!`)
        }
    }

    async removeRefreshToken(input: {
        userId: string,
        deviceId: string;
    }) {
        try {
            const refreshKey = `refresh_token:${input.userId}:${input.deviceId}`
            const userDevicesKey = `user_device:${input.userId}`
    
            await this.redisClient.multi()
                                    .del(refreshKey)
                                    .lrem(userDevicesKey, 0, input.deviceId)
                                    .exec()
        } catch (error) {
            console.log(`Cannot remove refreshToken: ${error}`);
            throw ErrorHandling.ServiceUnavailableError(`Cannot remove refreshToken now! Please try again later!`)
        }
    }

    async removeAllRefreshTokens(input: {
        userId: string,
    }) {
        try {
            const userDevicesKey = `user_device:${input.userId}`
    
            const deviceIds = await this.redisClient.lrange(userDevicesKey, 0, -1)
            if (!deviceIds || deviceIds.length === 0) {
                return;
            }
        } catch (error) {
            console.log(`Cannot remove all refreshToken: ${error}`);
            throw ErrorHandling.ServiceUnavailableError(`Cannot remove all refreshToken now! Please try again later!`)
        }
    }

    async verifyRefreshToken(input: {
        refreshToken: string,
    }) {
        try {
            const payload = await this.jwtService.verifyAsync<{
                userId: string,
                deviceId: string
            }>(
                input.refreshToken,
                {
                    secret: this.configService.get<string>('REFRESH_JWT_SECRET')
                }
            );

            const refreshKey = `refresh_token:${payload.userId}:${payload.deviceId}`
            const storedRefreshToken = await this.redisClient.get(refreshKey);
            if (!storedRefreshToken || storedRefreshToken !== input.refreshToken) {
                throw ErrorHandling.Unauthorized(`Refresh token is expired!`)
            }

            return payload;
        } catch (error) {
            console.log(`Redis Error verify refresh token: ${error}`);
            throw ErrorHandling.ServiceUnavailableError(`Cannot verify refresh token! Please try again later!`)
        }
    }
}