import { PrismaClient } from '@prisma/client';

declare global {
  // eslint-disable-next-line no-var
  var __prisma__: PrismaClient | undefined;
}

/**
 * A single shared PrismaClient instance. Reused across ts-node-dev hot reloads via the global
 * cache so we don't exhaust the Postgres connection pool in development.
 */
export const prisma = global.__prisma__ ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') {
  global.__prisma__ = prisma;
}
