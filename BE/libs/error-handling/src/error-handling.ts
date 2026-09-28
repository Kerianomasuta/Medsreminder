import { HttpStatus } from '@nestjs/common'
import { RpcException } from '@nestjs/microservices'
export class ErrorHandling {
    static BadRequest(message: string) {
        return new RpcException({
            status: HttpStatus.BAD_REQUEST,
            message: message
        })
    }

    static Unauthorized(message: string) {
        return new RpcException({
            status: HttpStatus.UNAUTHORIZED,
            message: message,
        })
    }

    static NotFound(message: string) {
        return new RpcException({
            status: HttpStatus.NOT_FOUND,
            message: message,
        })
    }
    
    static Conflict(message: string) {
        return new RpcException({
            status: HttpStatus.CONFLICT,
            message: message,
        })
    }

    static Forbidden(message: string) {
        return new RpcException({
            status: HttpStatus.FORBIDDEN,
            message: message,
        })
    }

    static AuthenticationFailed(message: string) {
        return new RpcException({
            status: 401,
            message: message,
        })
    }

    static InternalServerError(message: string) {
        return new RpcException({
            status: HttpStatus.INTERNAL_SERVER_ERROR,
            message: message,
        })
    }

    static ServiceUnavailableError(message: string) {
        return new RpcException({
            status: HttpStatus.SERVICE_UNAVAILABLE,
            message: message,
        })
    }
}