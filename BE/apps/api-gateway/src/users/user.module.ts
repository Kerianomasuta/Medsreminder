import { Module } from "@nestjs/common";
import { JwtModule } from "@nestjs/jwt";
import { UserController } from "./user.controller.js";
import { UserService } from "./user.service.js";
import { ClientsModule, Transport } from "@nestjs/microservices";
import { ConfigService } from "@nestjs/config";

@Module({
    imports: [
        JwtModule.register({}),

        ClientsModule.registerAsync([
            {
                name: 'USER_SERVICE',
                inject: [ConfigService],
                useFactory: (configService: ConfigService) => ({
                    transport: Transport.TCP,
                    options: {
                        host: configService.get<string>(`USER_SERVICE_HOST`),
                        port: configService.get<number>(`USER_SERVICE_PORT`)
                    }
                })
            }
        ])
    ],
    controllers: [
        UserController,
    ],
    providers: [
        UserService,
    ]
})
export class UserModule {}