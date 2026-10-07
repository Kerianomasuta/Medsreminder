import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from "@nestjs/common";
import type { Response } from "express";

@Catch()
export class RpcExceptionFilter implements ExceptionFilter {
    catch(exception: any, host: ArgumentsHost) {
        const response = host.switchToHttp().getResponse<Response>()

        if (exception instanceof HttpException) {
            const status = exception.getStatus()
            const body = exception.getResponse()

            return response.status(status).json(
                typeof body === 'string' ? { statusCode: status, message: body }
                                        : body
            );
        }

        const error = exception as {
            status?: unknown,
            message?: unknown,
        };

        if (
            typeof error?.status === 'number' &&
            typeof error?.message === 'string'
        ) {
            return response.status(error.status).json({
                statusCode: error.status,
                message: error.message,
            })
        }

        return response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
            statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
            message: error.message
        })
    }
}