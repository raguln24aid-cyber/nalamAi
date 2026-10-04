import { Router } from 'express';
import { asyncHandler } from '../../middleware/asyncHandler';
import { authGuard } from '../../middleware/authGuard';
import { validateBody, validateQuery } from '../../middleware/validate';
import { compareQuerySchema, createScanSchema, listScansQuerySchema } from '../extraction/schemas';
import { processScan } from '../extraction/extraction.service';
import * as productsService from './products.service';

export const scansRouter = Router();
scansRouter.use(authGuard);

scansRouter.post(
  '/',
  validateBody(createScanSchema),
  asyncHandler(async (req, res) => {
    const result = await processScan(req.user!.userId, req.body);
    res.status(202).json(result);
  }),
);

scansRouter.get(
  '/compare',
  validateQuery(compareQuerySchema),
  asyncHandler(async (req, res) => {
    const { a, b } = req.query as unknown as { a: string; b: string };
    const result = await productsService.compareScans(req.user!.userId, a, b);
    res.json(result);
  }),
);

scansRouter.get(
  '/',
  validateQuery(listScansQuerySchema),
  asyncHandler(async (req, res) => {
    const { limit, cursor } = req.query as unknown as { limit: number; cursor?: string };
    const result = await productsService.listScans(req.user!.userId, limit, cursor);
    res.json(result);
  }),
);

scansRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const result = await productsService.getScan(req.user!.userId, req.params.id!);
    res.json(result);
  }),
);
