import { Module } from "@nestjs/common";
import { AuthController } from "./auth.controller.js";
import { UserModule } from "../users/user.module.js";
import { AuthService } from "./auth.service.js";
import { JwtModule } from '@nestjs/jwt'
import { TokenService } from "../token/token.service.js";

@Module({
    imports: [
        UserModule,

        JwtModule.register({})
    ],
    controllers: [AuthController],
    providers: [
        AuthService,
        TokenService,
    ]
})
export class AuthModule {}