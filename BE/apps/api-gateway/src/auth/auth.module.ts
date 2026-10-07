import { Module } from "@nestjs/common";
import { AuthController } from "./auth.controller.js";
import { AuthService } from "./auth.service.js";
import { ClientsModule, Transport } from "@nestjs/microservices"
import { ConfigService } from "@nestjs/config";
import { JwtModule } from '@nestjs/jwt'
import { JwtAuthGuard } from "./guards/jwt-auth.guards.js";
import { RolesGuard } from "./guards/authorizedByRoles/roles.guard.js";

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
                        host: configService.get<string>('USER_SERVICE_HOST'),
                        port: configService.get<number>('USER_SERVICE_PORT')
                    }
                })
            }
        ])
    ],
    controllers: [AuthController],
    providers: [
        AuthService,
        JwtAuthGuard,
        RolesGuard,
    ],
    exports: [
        JwtModule,
        JwtAuthGuard,
        RolesGuard,
    ]
})
export class AuthModule {}