/**
 * General-population reference thresholds (per 100g), broadly aligned with FSSAI/Codex "high in"
 * conventions. These are informational reference points, not medical cutoffs for any individual
 * — see docs/SAFETY_RULES.md. Always phrased as "relatively high compared to general reference
 * levels", never "bad for you".
 */
export const NUTRITION_THRESHOLDS = {
  sugarG: 22.5,
  saturatedFatG: 5,
  sodiumMg: 600,
} as const;

export interface NutritionThresholdFlag {
  field: keyof typeof NUTRITION_THRESHOLDS;
  value: number;
  threshold: number;
  message: string;
}

export function checkNutritionThresholds(nutrition: {
  sugarG: number | null;
  saturatedFatG: number | null;
  sodiumMg: number | null;
}): NutritionThresholdFlag[] {
  const flags: NutritionThresholdFlag[] = [];

  if (nutrition.sugarG !== null && nutrition.sugarG >= NUTRITION_THRESHOLDS.sugarG) {
    flags.push({
      field: 'sugarG',
      value: nutrition.sugarG,
      threshold: NUTRITION_THRESHOLDS.sugarG,
      message: `This product has ${nutrition.sugarG}g of sugar per 100g, which is relatively high compared to general reference levels (${NUTRITION_THRESHOLDS.sugarG}g).`,
    });
  }
  if (nutrition.saturatedFatG !== null && nutrition.saturatedFatG >= NUTRITION_THRESHOLDS.saturatedFatG) {
    flags.push({
      field: 'saturatedFatG',
      value: nutrition.saturatedFatG,
      threshold: NUTRITION_THRESHOLDS.saturatedFatG,
      message: `This product has ${nutrition.saturatedFatG}g of saturated fat per 100g, which is relatively high compared to general reference levels (${NUTRITION_THRESHOLDS.saturatedFatG}g).`,
    });
  }
  if (nutrition.sodiumMg !== null && nutrition.sodiumMg >= NUTRITION_THRESHOLDS.sodiumMg) {
    flags.push({
      field: 'sodiumMg',
      value: nutrition.sodiumMg,
      threshold: NUTRITION_THRESHOLDS.sodiumMg,
      message: `This product has ${nutrition.sodiumMg}mg of sodium per 100g, which is relatively high compared to general reference levels (${NUTRITION_THRESHOLDS.sodiumMg}mg).`,
    });
  }

  return flags;
}
