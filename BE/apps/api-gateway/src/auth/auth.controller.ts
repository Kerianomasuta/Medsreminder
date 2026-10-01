import { Body, Controller, Delete, Post, Req, Res, UnauthorizedException, UseGuards, HttpException } from "@nestjs/common";
import { AuthService } from "./auth.service.js";
import { LoginDto } from "./dto/login.dto.js";
import { lastValueFrom } from "rxjs";
import type { Request, Response } from "express";
import { ConfigService } from "@nestjs/config";
import { ApiCookieAuth, ApiOperation, ApiResponse, ApiTags } from "@nestjs/swagger";
import { JwtAuthGuard } from "./guards/jwt-auth.guards.js";

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
        let tcpResponse;
        try {
            tcpResponse = await lastValueFrom(this.authService.login(loginDto));
        } catch (error) {
            throw new HttpException(error.message || 'Internal server error', error.status || 500);
        }
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

    @Delete('logout')
    @UseGuards(JwtAuthGuard)
    @ApiOperation({ summary: 'Log out the current device' })
    @ApiCookieAuth('accessToken')
    @ApiResponse({
        status: 200,
        description: 'Logout succeeded. Access and refresh token cookies are cleared.',
        schema: {
            example: {
                status: 200,
                message: 'Logout successfully',
            },
        },
        headers: {
            'Set-Cookie': {
                description: 'Clears the HTTP-only accessToken and refreshToken cookies',
                schema: { type: 'string' },
            },
        },
    })
    @ApiResponse({ status: 401, description: 'Access token is missing or invalid.' })
    async logout(
        @Res({ passthrough: true }) res: Response,
        @Req() req: Request
    ) {
        const { userId, deviceId } = (req as any).user

        const tcpResponse = await lastValueFrom(
            this.authService.logout({
                userId,
                deviceId,
            })
        );

        if (tcpResponse?.status === 200) {
            res.clearCookie('accessToken')
            res.clearCookie('refreshToken')
        }

        return {
            status: tcpResponse.status,
            message: 'Logout successfully'
        }
    }

    @Post('refreshToken')
    @ApiOperation({ summary: 'Refresh access and refresh tokens' })
    @ApiCookieAuth('refreshToken')
    @ApiResponse({
        status: 200,
        description: 'Tokens refreshed successfully. New tokens are set as HTTP-only cookies.',
        schema: {
            example: {
                status: 200,
                message: 'refresh token successfully!',
            },
        },
        headers: {
            'Set-Cookie': {
                description: 'New HTTP-only accessToken and refreshToken cookies',
                schema: { type: 'string' },
            },
        },
    })
    @ApiResponse({ status: 401, description: 'Refresh token is missing or invalid.' })
    async refreshToken(
        @Req() req: Request,
        @Res({ passthrough: true }) res: Response
    ) {
        const refreshToken = req.cookies?.refreshToken;
        if (!refreshToken) {
            throw new UnauthorizedException(`Missing refresh token from cookie!`)
        }

        const tcpResponse = await lastValueFrom(
            this.authService.refreshToken({
                oldRefreshToken: refreshToken
            })
        )

        if (tcpResponse?.status === 200) {
            res.cookie('accessToken', tcpResponse?.data?.accessToken, {
                httpOnly: true,
                secure: this.configService.get<string>('NODE_ENV') === 'production',
                sameSite: 'strict',
                maxAge: ACCESS_TOKEN_MAX_AGE,
            })

            res.cookie('refreshToken', tcpResponse?.data?.refreshToken, {
                httpOnly: true,
                secure: this.configService.get<string>('NODE_ENV') === 'production',
                sameSite: 'strict',
                maxAge: REFRESH_TOKEN_MAX_AGE,
            })
        }

        delete tcpResponse?.data

        return {
            status: 200,
            message: 'refresh token successfully!'
        }
    }
}