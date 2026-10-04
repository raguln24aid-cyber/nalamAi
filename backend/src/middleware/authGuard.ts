import { NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../modules/auth/jwt';
import { unauthorized } from '../lib/errors';

export function authGuard(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    next(unauthorized('Missing bearer token'));
    return;
  }

  const token = header.slice('Bearer '.length);
  try {
    const payload = verifyAccessToken(token);
    req.user = { userId: payload.userId, email: payload.email };
    next();
  } catch {
    next(unauthorized('Invalid or expired access token'));
  }
}
