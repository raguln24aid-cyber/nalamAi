import pino from 'pino';
import { loadConfig } from './config';

const config = loadConfig();

/**
 * Structured JSON logger. Never log raw request bodies (they may contain photo base64 data or
 * OCR text with PII) or emails in plaintext — see redact paths below.
 */
export const logger = pino({
  level: config.LOG_LEVEL,
  redact: {
    paths: [
      'req.body.imageBase64',
      'req.body.password',
      'req.headers.authorization',
      '*.passwordHash',
      '*.accessToken',
      '*.refreshToken',
    ],
    censor: '[redacted]',
  },
  transport:
    config.NODE_ENV === 'development'
      ? { target: 'pino-pretty', options: { colorize: true, translateTime: 'HH:MM:ss' } }
      : undefined,
});

export type Logger = typeof logger;
