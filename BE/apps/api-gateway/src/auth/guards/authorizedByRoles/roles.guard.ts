import { CanActivate, ExecutionContext, ForbiddenException, Injectable, UnauthorizedException } from "@nestjs/common";
import { ROLES_KEY, UserRole } from "./roles.decorator.js"
import { Reflector } from "@nestjs/core";

type AccessTokenPayload = {
    userId: string,
    deviceId: string,
    fullName: string,
    role: UserRole;
};

type AuthenticatedRequest = Request & {
    user?: AccessTokenPayload,
}

@Injectable()
export class RolesGuard implements CanActivate {
    constructor(
        private readonly reflector: Reflector,
    ) {}

    canActivate(context: ExecutionContext): boolean {
        const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(
            ROLES_KEY,
            [context.getHandler(), context.getClass()],
        );

        if (!requiredRoles || requiredRoles.length === 0) {
            return true
        }

        const request = context.switchToHttp().getRequest<AuthenticatedRequest>();

        const user = request.user
        if (!user) {
            throw new UnauthorizedException('User is unauthenticated')
        }

        if (!requiredRoles.includes(user.role)) {
            throw new ForbiddenException(`You do not have permission`)
        }

        return true;
    }
}