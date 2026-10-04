import { z } from 'zod';

export const synthesizeSchema = z.object({
  text: z.string().trim().min(1).max(1000),
  language: z.enum(['en', 'ta']),
});
