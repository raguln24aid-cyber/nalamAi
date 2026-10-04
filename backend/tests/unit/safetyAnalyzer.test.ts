import { analyzeSafety } from '../../src/modules/safety/safetyAnalyzer';

describe('analyzeSafety', () => {
  it('flags a critical allergen_match when a declared allergen matches the user profile', () => {
    const flags = analyzeSafety({
      productAllergens: [{ name: 'peanuts', declared: true }],
      nutrition: { sugarG: null, saturatedFatG: null, sodiumMg: null },
      userAllergies: [{ allergen: 'peanuts', severity: 'severe' }],
    });

    expect(flags).toContainEqual(
      expect.objectContaining({ type: 'allergen_match', severity: 'critical', provenance: 'label_stated' }),
    );
  });

  it('flags possible_allergen_unconfirmed (not allergen_match) for inferred, undeclared allergens', () => {
    const flags = analyzeSafety({
      productAllergens: [{ name: 'milk', declared: false }],
      nutrition: { sugarG: null, saturatedFatG: null, sodiumMg: null },
      userAllergies: [{ allergen: 'milk', severity: 'moderate' }],
    });

    expect(flags).toContainEqual(
      expect.objectContaining({ type: 'possible_allergen_unconfirmed', severity: 'warning' }),
    );
    expect(flags.find((f) => f.type === 'allergen_match')).toBeUndefined();
  });

  it('does not flag allergens the user has not declared', () => {
    const flags = analyzeSafety({
      productAllergens: [{ name: 'soy', declared: true }],
      nutrition: { sugarG: null, saturatedFatG: null, sodiumMg: null },
      userAllergies: [{ allergen: 'peanuts', severity: 'severe' }],
    });
    expect(flags.filter((f) => f.type !== 'nutrition_threshold')).toHaveLength(0);
  });

  it('flags high-sugar nutrition thresholds as informational, not critical', () => {
    const flags = analyzeSafety({
      productAllergens: [],
      nutrition: { sugarG: 30, saturatedFatG: null, sodiumMg: null },
      userAllergies: [],
    });
    expect(flags).toContainEqual(
      expect.objectContaining({ type: 'nutrition_threshold', severity: 'info' }),
    );
  });

  it('never emits a bare "safe" or "good"/"bad" verdict message', () => {
    const flags = analyzeSafety({
      productAllergens: [{ name: 'peanuts', declared: true }],
      nutrition: { sugarG: 30, saturatedFatG: 10, sodiumMg: 800 },
      userAllergies: [{ allergen: 'peanuts', severity: 'severe' }],
    });
    for (const flag of flags) {
      expect(flag.message.toLowerCase()).not.toMatch(/\b(safe|good food|bad food|unhealthy|healthy)\b/);
    }
  });
});
