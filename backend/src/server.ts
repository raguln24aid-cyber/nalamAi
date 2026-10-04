// Must run before any other import touches process.env (lib/config reads it eagerly via zod).
// In production, real deployment platforms inject env vars directly and this is a no-op since
// no .env file is present — see backend/README.md.
import 'dotenv/config';

import { createApp } from './app';
import { loadConfig } from './lib/config';
import { logger } from './lib/logger';

const config = loadConfig();
const app = createApp();

const server = app.listen(config.PORT, () => {
  logger.info(`NalamAI backend listening on port ${config.PORT} (${config.NODE_ENV})`);
});

function shutdown(signal: string): void {
  logger.info(`Received ${signal}, shutting down gracefully`);
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('unhandledRejection', (reason) => {
  logger.error({ reason }, 'Unhandled promise rejection');
});
