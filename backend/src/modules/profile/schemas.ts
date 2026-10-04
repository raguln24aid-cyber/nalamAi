import { z } from 'zod';

export const dietaryPreferenceEnum = z.enum([
  'none',
  'vegetarian',
  'vegan',
  'eggetarian',
  'non_vegetarian',
]);

export const updateProfileSchema = z.object({
  dietaryPreference: dietaryPreferenceEnum.optional(),
  notes: z.string().max(1000).nullable().optional(),
});

export const addAllergySchema = z.object({
  allergen: z.string().trim().min(1).max(100),
  severity: z.enum(['mild', 'moderate', 'severe']).default('moderate'),
});

export const addRestrictionSchema = z.object({
  restriction: z.string().trim().min(1).max(200),
});
