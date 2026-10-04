import { z } from 'zod';

export const assistantQuerySchema = z.object({
  scanId: z.string().uuid(),
  question: z.string().trim().min(1).max(500),
  language: z.enum(['en', 'ta', 'auto']).default('auto'),
  compareScanId: z.string().uuid().optional(),
});

export const assistantHistoryQuerySchema = z.object({
  scanId: z.string().uuid(),
});
