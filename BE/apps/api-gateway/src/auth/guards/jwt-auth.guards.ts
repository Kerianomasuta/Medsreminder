import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { JwtService } from "@nestjs/jwt";
import { Request } from "express";
import { Observable } from "rxjs";

@Injectable()
export class JwtAuthGuard implements CanActivate {
    constructor(
        private readonly jwtService: JwtService,
        private readonly configService: ConfigService,
    ) {}

    async canActivate(context: ExecutionContext): Promise<boolean> {
        const request = context.switchToHttp().getRequest<Request>();

        const token = request.cookies?.accessToken;
        if (!token) {
            throw new UnauthorizedException(`Token is missing from cookies!`);
        }

        try {
            const payload = await this.jwtService.verifyAsync(token, {
                secret: this.configService.get<string>('ACCESS_JWT_SECRET')
            });

            (request as Request & { user: unknown }).user = payload;

            return true;
        } catch (error) {
            throw new UnauthorizedException(`Token expired!`)
        }
    }
}