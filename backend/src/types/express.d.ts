import 'express';

declare global {
  namespace Express {
    interface Request {
      /** Correlation id set by pino-http for structured logging. */
      id?: string;
      /** Populated by the auth guard middleware once a valid access token is verified. */
      user?: {
        userId: string;
        email: string;
      };
    }
  }
}
