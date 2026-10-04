import { z } from 'zod';

export const createScanSchema = z
  .object({
    imageBase64: z.string().min(1).optional(),
    barcode: z
      .string()
      .trim()
      .regex(/^\d{8,14}$/, 'Barcode must be 8-14 digits')
      .optional(),
    languageHint: z.enum(['en', 'ta', 'auto']).default('auto'),
  })
  .refine((data) => Boolean(data.imageBase64 || data.barcode), {
    message: 'At least one of imageBase64 or barcode is required',
  });

export type CreateScanInput = z.infer<typeof createScanSchema>;

export const compareQuerySchema = z.object({
  a: z.string().uuid(),
  b: z.string().uuid(),
});

export const listScansQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  cursor: z.string().uuid().optional(),
});
