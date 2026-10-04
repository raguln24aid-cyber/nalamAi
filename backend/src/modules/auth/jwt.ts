import jwt, { SignOptions } from 'jsonwebtoken';
import { loadConfig } from '../../lib/config';

export interface AccessTokenPayload {
  userId: string;
  email: string;
}

export interface RefreshTokenPayload {
  userId: string;
  tokenId: string;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  const config = loadConfig();
  const options: SignOptions = { expiresIn: config.JWT_ACCESS_TTL as SignOptions['expiresIn'] };
  return jwt.sign(payload, config.JWT_ACCESS_SECRET, options);
}

export function signRefreshToken(payload: RefreshTokenPayload): string {
  const config = loadConfig();
  const options: SignOptions = { expiresIn: config.JWT_REFRESH_TTL as SignOptions['expiresIn'] };
  return jwt.sign(payload, config.JWT_REFRESH_SECRET, options);
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const config = loadConfig();
  return jwt.verify(token, config.JWT_ACCESS_SECRET) as AccessTokenPayload & jwt.JwtPayload;
}

export function verifyRefreshToken(token: string): RefreshTokenPayload {
  const config = loadConfig();
  return jwt.verify(token, config.JWT_REFRESH_SECRET) as RefreshTokenPayload & jwt.JwtPayload;
}
