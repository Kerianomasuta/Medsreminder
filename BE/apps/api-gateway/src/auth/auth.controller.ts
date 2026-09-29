import { Body, Controller, Post, Res } from "@nestjs/common";
import { AuthService } from "./auth.service.js";
import { LoginDto } from "./dto/login.dto.js";
import { lastValueFrom } from "rxjs";
import type { Response } from "express";
import { ConfigService } from "@nestjs/config";
import { ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";

const ACCESS_TOKEN_MAX_AGE = 15 * 60 * 1000
const REFRESH_TOKEN_MAX_AGE = 7 * 24 * 60 * 60 * 1000

@Controller('api/v1/auth')
@ApiTags('Authentication')
export class AuthController {
    constructor(
        private readonly authService: AuthService,
        private readonly configService: ConfigService
    ) {}

    @Post('login')
    @ApiOperation({ summary: 'Log in a user' })
    @ApiResponse({
        status: 200,
        description: 'Login succeeded. Access and refresh tokens are set as HTTP-only cookies.',
        schema: {
            example: {
                status: 'success',
                message: 'Login successfully!',
            },
        },
        headers: {
            'Set-Cookie': {
                description: 'HTTP-only accessToken and refreshToken cookies',
                schema: { type: 'string' },
            },
        },
    })
    @ApiResponse({ status: 400, description: 'Invalid email or password format.' })
    async login (
        @Body() loginDto: LoginDto,
        @Res({ passthrough: true }) res: Response,
    ) {
        const tcpResponse = await lastValueFrom(this.authService.login(loginDto))

        if (tcpResponse?.status === 200) {
            res.cookie('accessToken', tcpResponse?.data?.accessToken, {
                httpOnly: true,
                secure: this.configService.get<string>('NODE_ENV') === 'production',
                sameSite: 'strict',
                maxAge: ACCESS_TOKEN_MAX_AGE,
            })

            res.cookie('refreshToken', tcpResponse?.data?.refreshToken, {
                httpOnly: true,
                secure: this.configService.get<string>("NODE_ENV") === 'production',
                sameSite: 'strict',
                maxAge: REFRESH_TOKEN_MAX_AGE,
            })
        }

        delete tcpResponse?.data
        return {
            status: 'success',
            message: 'Login successfully!',
        }
    }
}