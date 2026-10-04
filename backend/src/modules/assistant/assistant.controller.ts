import { Router } from 'express';
import { asyncHandler } from '../../middleware/asyncHandler';
import { authGuard } from '../../middleware/authGuard';
import { validateBody, validateQuery } from '../../middleware/validate';
import { assistantHistoryQuerySchema, assistantQuerySchema } from './schemas';
import * as assistantService from './assistant.service';

export const assistantRouter = Router();
assistantRouter.use(authGuard);

assistantRouter.post(
  '/query',
  validateBody(assistantQuerySchema),
  asyncHandler(async (req, res) => {
    const result = await assistantService.query(req.user!.userId, req.body);
    res.json(result);
  }),
);

assistantRouter.get(
  '/history',
  validateQuery(assistantHistoryQuerySchema),
  asyncHandler(async (req, res) => {
    const { scanId } = req.query as unknown as { scanId: string };
    const result = await assistantService.getHistory(req.user!.userId, scanId);
    res.json(result);
  }),
);
