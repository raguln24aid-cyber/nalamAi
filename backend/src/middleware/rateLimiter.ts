import rateLimit from 'express-rate-limit';
import { loadConfig } from '../lib/config';

/** General API rate limiter — keyed by IP, falls back to authenticated user id when present. */
export function buildRateLimiter() {
  const config = loadConfig();
  return rateLimit({
    windowMs: config.RATE_LIMIT_WINDOW_MS,
    max: config.RATE_LIMIT_MAX_REQUESTS,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => req.user?.userId ?? req.ip ?? 'unknown',
    handler: (_req, res) => {
      res.status(429).json({
        error: { code: 'RATE_LIMITED', message: 'Too many requests. Please slow down.' },
      });
    },
  });
}

/** Stricter limiter for auth endpoints to slow down credential-stuffing attempts. */
export function buildAuthRateLimiter() {
  return rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (_req, res) => {
      res.status(429).json({
        error: { code: 'RATE_LIMITED', message: 'Too many attempts. Please try again later.' },
      });
    },
  });
}
