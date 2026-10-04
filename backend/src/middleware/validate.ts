import { NextFunction, Request, Response } from 'express';
import { ZodError, ZodTypeAny } from 'zod';
import { AppError } from '../lib/errors';

/** Validates req.body against a Zod schema and replaces it with the parsed (typed) value. */
export function validateBody(schema: ZodTypeAny) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      next(toValidationError(result.error));
      return;
    }
    req.body = result.data;
    next();
  };
}

export function validateQuery(schema: ZodTypeAny) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      next(toValidationError(result.error));
      return;
    }
    req.query = result.data as never;
    next();
  };
}

function toValidationError(error: ZodError): AppError {
  return new AppError('VALIDATION_ERROR', 'Request validation failed', {
    issues: error.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
  });
}
