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
} 