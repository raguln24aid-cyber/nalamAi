import { checkNutritionThresholds } from './nutritionThresholds';

export type SafetyFlagType = 'allergen_match' | 'nutrition_threshold' | 'possible_allergen_unconfirmed';
export type SafetyFlagSeverity = 'info' | 'warning' | 'critical';
export type ProvenanceSource = 'label_stated' | 'ocr_detected' | 'ai_interpreted' | 'unverified';

export interface SafetyFlagDraft {
  type: SafetyFlagType;
  severity: SafetyFlagSeverity;
  message: string;
  provenance: ProvenanceSource;
}

export interface ProductAllergen {
  name: string;
  declared: boolean;
}

export interface ProfileAllergy {
  allergen: string;
  severity: 'mild' | 'moderate' | 'severe';
}

/**
 * Rule-based (no LLM) comparison of a product against a user's profile. This is the primary
 * safety signal — see docs/SAFETY_RULES.md — and never depends on model behavior.
 */
export function analyzeSafety(params: {
  productAllergens: ProductAllergen[];
  nutrition: { sugarG: number | null; saturatedFatG: number | null; sodiumMg: number | null };
  userAllergies: ProfileAllergy[];
}): SafetyFlagDraft[] {
  const flags: SafetyFlagDraft[] = [];

  for (const userAllergy of params.userAllergies) {
    const normalizedUserAllergen = userAllergy.allergen.toLowerCase().trim();
    const match = params.productAllergens.find((a) =>
      matchesAllergen(a.name.toLowerCase(), normalizedUserAllergen),
    );
    if (!match) continue;

    if (match.declared) {
      flags.push({
        type: 'allergen_match',
        severity: 'critical',
        message: `The label explicitly declares "${match.name}", which matches "${userAllergy.allergen}" in your allergy profile.`,
        provenance: 'label_stated',
      });
    } else {
      flags.push({
        type: 'possible_allergen_unconfirmed',
        severity: 'warning',
        message: `The label does not carry an explicit allergen declaration, but an ingredient matching "${match.name}" was detected, which may relate to "${userAllergy.allergen}" in your allergy profile. This could not be verified as an official allergen declaration.`,
        provenance: 'ocr_detected',
      });
    }
  }

  const thresholdFlags = checkNutritionThresholds(params.nutrition);
  for (const t of thresholdFlags) {
    flags.push({
      type: 'nutrition_threshold',
      severity: 'info',
      message: t.message,
      provenance: 'ai_interpreted',
    });
  }

  return flags;
}

function matchesAllergen(productAllergen: string, userAllergen: string): boolean {
  return productAllergen.includes(userAllergen) || userAllergen.includes(productAllergen);
}
