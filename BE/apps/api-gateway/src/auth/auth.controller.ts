import { Body, Controller, Post, Res } from "@nestjs/common";
import { AuthService } from "./auth.service.js";
import { LoginDto } from "./dto/login.dto.js";
import { lastValueFrom } from "rxjs";

@Controller('api/v1/auth')
export class AuthController {
    constructor(
        private readonly authService: AuthService
    ) {}

    @Post('login')
    async login (
        @Body() loginDto: LoginDto,
        @Res({ passthrough: true }) res: Response,
    ) {
        const tcpResponse = await lastValueFrom(this.authService.login(loginDto))
    }
}