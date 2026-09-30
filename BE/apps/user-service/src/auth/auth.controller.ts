import { Controller } from "@nestjs/common";
import { AuthService } from "./auth.service.js";
import { MessagePattern, Payload } from "@nestjs/microservices";

@Controller('')
export class AuthController {
    constructor(
        private readonly authService: AuthService,
    ) {}

    @MessagePattern({ cmd: 'handle_user_login' })
    async handleUserLogin(@Payload() data: any) {
        return this.authService.handleUserLogin(data)
    }

    @MessagePattern({ cmd: 'handle_user_logout' })
    async handleUserLogout(@Payload() data: any) {
        return this.authService.handleUserLogout(data)
    }

    @MessagePattern({ cmd: 'handle_user_refresh_token' })
    async handleUserRefreshToken(@Payload() data: any) {
        return this.authService.handleUserRefreshToken(data)
    }
} 