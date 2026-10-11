import { HttpException, HttpStatus } from '@nestjs/common';

export function toRpcHttpException(error: unknown, unavailableMessage: string) {
  if (error instanceof HttpException) {
    return error;
  }
  const parsed = readRpcError(error);
  if (parsed) {
    return new HttpException(parsed.message, parsed.status);
  }
  return new HttpException(unavailableMessage, HttpStatus.SERVICE_UNAVAILABLE);
}

function readRpcError(error: unknown): { status: number; message: string } | undefined {
  if (typeof error !== 'object' || error === null) {
    return undefined;
  }
  const record = error as { status?: unknown; message?: unknown };
  if (typeof record.message === 'object' && record.message !== null) {
    const nested = readRpcError(record.message);
    if (nested) {
      return nested;
    }
  }
  if (typeof record.status === 'number' && typeof record.message === 'string') {
    return { status: record.status, message: record.message };
  }
  if (record.status === 'error' && typeof record.message === 'string') {
    return { status: HttpStatus.INTERNAL_SERVER_ERROR, message: record.message };
  }
  return undefined;
}
