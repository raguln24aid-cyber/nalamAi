import bcrypt from 'bcryptjs';
import crypto from 'node:crypto';
import { v4 as uuid } from 'uuid';
import { prisma } from '../../lib/prisma';
import { AppError } from '../../lib/errors';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from './jwt';
import { LoginInput, RegisterInput } from './schemas';

const BCRYPT_ROUNDS = 12;

function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function ttlToMs(ttl: string): number {
  const match = /^(\d+)([smhd])$/.exec(ttl);
  if (!match) return 30 * 24 * 60 * 60 * 1000;
  const value = Number(match[1]);
  const unit = match[2];
  const multiplier = { s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 }[unit as 's' | 'm' | 'h' | 'd'];
  return value * multiplier;
}

export interface AuthResult {
  user: { id: string; email: string; preferredLanguage: string; createdAt: Date };
  accessToken: string;
  refreshToken: string;
}

async function issueTokenPair(userId: string, email: string): Promise<{ accessToken: string; refreshToken: string }> {
  const tokenId = uuid();
  const refreshToken = signRefreshToken({ userId, tokenId });
  const accessToken = signAccessToken({ userId, email });

  await prisma.refreshToken.create({
    data: {
      id: tokenId,
      userId,
      tokenHash: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + ttlToMs(process.env.JWT_REFRESH_TTL ?? '30d')),
    },
  });

  return { accessToken, refreshToken };
}

export async function register(input: RegisterInput): Promise<AuthResult> {
  const existing = await prisma.user.findUnique({ where: { email: input.email } });
  if (existing) {
    throw new AppError('CONFLICT', 'An account with this email already exists');
  }

  const passwordHash = await bcrypt.hash(input.password, BCRYPT_ROUNDS);
  const user = await prisma.user.create({
    data: {
      email: input.email,
      passwordHash,
      preferredLanguage: input.preferredLanguage,
      profile: { create: {} },
    },
  });

  const tokens = await issueTokenPair(user.id, user.email);
  return {
    user: {
      id: user.id,
      email: user.email,
      preferredLanguage: user.preferredLanguage,
      createdAt: user.createdAt,
    },
    ...tokens,
  };
}

export async function login(input: LoginInput): Promise<AuthResult> {
  const user = await prisma.user.findUnique({ where: { email: input.email } });
  // Intentionally identical error for "no such user" and "wrong password" to avoid
  // leaking which emails are registered.
  const invalidCredentials = () => new AppError('UNAUTHORIZED', 'Invalid email or password');

  if (!user) throw invalidCredentials();

  const valid = await bcrypt.compare(input.password, user.passwordHash);
  if (!valid) throw invalidCredentials();

  const tokens = await issueTokenPair(user.id, user.email);
  return {
    user: {
      id: user.id,
      email: user.email,
      preferredLanguage: user.preferredLanguage,
      createdAt: user.createdAt,
    },
    ...tokens,
  };
}

export async function refresh(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw new AppError('UNAUTHORIZED', 'Invalid or expired refresh token');
  }

  const stored = await prisma.refreshToken.findUnique({ where: { id: payload.tokenId } });
  if (!stored || stored.revokedAt || stored.tokenHash !== hashToken(refreshToken) || stored.expiresAt < new Date()) {
    throw new AppError('UNAUTHORIZED', 'Invalid or expired refresh token');
  }

  const user = await prisma.user.findUnique({ where: { id: payload.userId } });
  if (!user) throw new AppError('UNAUTHORIZED', 'Invalid or expired refresh token');

  // Rotate: revoke the old token, issue a new pair.
  await prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
  return issueTokenPair(user.id, user.email);
}

export async function logout(refreshToken: string): Promise<void> {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    return; // already invalid — nothing to revoke
  }
  await prisma.refreshToken.updateMany({
    where: { id: payload.tokenId, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}
