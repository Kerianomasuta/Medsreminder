import { Catch, HttpStatus, type ArgumentsHost } from '@nestjs/common';
import { BaseRpcExceptionFilter, RpcException } from '@nestjs/microservices';
import { throwError } from 'rxjs';

@Catch()
export class RpcErrorFilter extends BaseRpcExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    if (exception instanceof RpcException) {
      return super.catch(exception, host);
    }
    const message = exception instanceof Error ? exception.message : 'Internal server error';
    return throwError(() => ({ status: HttpStatus.INTERNAL_SERVER_ERROR, message }));
  }
}
