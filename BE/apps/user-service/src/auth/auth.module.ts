import { Module } from "@nestjs/common";
import { AuthController } from "./auth.controller.js";
import { UserModule } from "../users/user.module.js";
import { AuthService } from "./auth.service.js";

@Module({
    imports: [
        UserModule
    ],
    controllers: [AuthController],
    providers: [AuthService]
})
export class AuthModule {}