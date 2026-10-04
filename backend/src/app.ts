import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import { randomUUID } from 'node:crypto';
import { loadConfig } from './lib/config';
import { logger } from './lib/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { buildRateLimiter } from './middleware/rateLimiter';
import { authRouter } from './modules/auth/auth.controller';
import { profileRouter } from './modules/profile/profile.controller';
import { scansRouter } from './modules/products/products.controller';
import { assistantRouter } from './modules/assistant/assistant.controller';
import { ttsRouter } from './modules/tts/tts.controller';

const APP_VERSION = process.env.npm_package_version ?? '1.0.0';

export function createApp(): Express {
  const config = loadConfig();
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin: config.corsAllowedOrigins.length > 0 ? config.corsAllowedOrigins : true,
      credentials: true,
    }),
  );
  app.use(express.json({ limit: '8mb' }));
  app.use(
    pinoHttp({
      logger,
      genReqId: (req, res) => {
        const existing = req.headers['x-request-id'];
        const id = typeof existing === 'string' ? existing : randomUUID();
        res.setHeader('x-request-id', id);
        return id;
      },
    }),
  );

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', version: APP_VERSION });
  });

  app.use(buildRateLimiter());

  app.use('/api/v1/auth', authRouter);
  app.use('/api/v1/profile', profileRouter);
  app.use('/api/v1/scans', scansRouter);
  app.use('/api/v1/assistant', assistantRouter);
  app.use('/api/v1/tts', ttsRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
