import { Router } from 'express';
import { asyncHandler } from '../../middleware/asyncHandler';
import { validateBody } from '../../middleware/validate';
import { authGuard } from '../../middleware/authGuard';
import { buildAuthRateLimiter } from '../../middleware/rateLimiter';
import { loginSchema, refreshSchema, registerSchema } from './schemas';
import * as authService from './auth.service';

export const authRouter = Router();
const authLimiter = buildAuthRateLimiter();

authRouter.post(
  '/register',
  authLimiter,
  validateBody(registerSchema),
  asyncHandler(async (req, res) => {
    const result = await authService.register(req.body);
    res.status(201).json(result);
  }),
);

authRouter.post(
  '/login',
  authLimiter,
  validateBody(loginSchema),
  asyncHandler(async (req, res) => {
    const result = await authService.login(req.body);
    res.status(200).json(result);
  }),
);

authRouter.post(
  '/refresh',
  authLimiter,
  validateBody(refreshSchema),
  asyncHandler(async (req, res) => {
    const result = await authService.refresh(req.body.refreshToken);
    res.status(200).json(result);
  }),
);

authRouter.post(
  '/logout',
  authGuard,
  validateBody(refreshSchema),
  asyncHandler(async (req, res) => {
    await authService.logout(req.body.refreshToken);
    res.status(204).send();
  }),
);
