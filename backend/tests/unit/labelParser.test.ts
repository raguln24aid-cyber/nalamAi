import { parseAllergensAndDietFlags, parseIngredients, parseLabel, parseNutrition, parseProductName } from '../../src/modules/nutrition/labelParser';

const SAMPLE_LABEL = `NALAM SNACKS
Roasted Peanut Mix
Nutrition Information (per 100g)
Energy 520 kcal
Protein 18g
Total Fat 42g
Saturated Fat 8g
Total Sugars 6g
Sodium 380mg
Dietary Fibre 7g
Ingredients: Peanuts, Refined Palm Oil, Salt, Sugar, Milk Solids, Spices
Contains: Peanuts, Milk
Vegetarian`;

describe('parseNutrition', () => {
  it('extracts all known nutrition fields from a well-formed label', () => {
    const result = parseNutrition(SAMPLE_LABEL);
    expect(result).toMatchObject({
      calories: 520,
      proteinG: 18,
      fatG: 42,
      saturatedFatG: 8,
      sugarG: 6,
      sodiumMg: 380,
      fiberG: 7,
      provenance: 'ocr_detected',
    });
  });

  it('marks nutrition as unverified when nothing matches', () => {
    const result = parseNutrition('Just some random unrelated text with no numbers.');
    expect(result.provenance).toBe('unverified');
    expect(result.calories).toBeNull();
  });
});

describe('parseIngredients', () => {
  it('splits the ingredients section on commas', () => {
    const ingredients = parseIngredients(SAMPLE_LABEL);
    expect(ingredients).toEqual(['Peanuts', 'Refined Palm Oil', 'Salt', 'Sugar', 'Milk Solids', 'Spices']);
  });

  it('returns an empty array when there is no ingredients section', () => {
    expect(parseIngredients('No relevant section here.')).toEqual([]);
  });
});

describe('parseAllergensAndDietFlags', () => {
  it('marks explicitly declared allergens as label_stated with declared=true', () => {
    const ingredients = parseIngredients(SAMPLE_LABEL);
    const { allergens } = parseAllergensAndDietFlags(SAMPLE_LABEL, ingredients);
    const peanut = allergens.find((a) => a.name === 'peanuts');
    expect(peanut).toMatchObject({ declared: true, provenance: 'label_stated' });
  });

  it('infers undeclared allergens from ingredient keywords with declared=false', () => {
    const { allergens } = parseAllergensAndDietFlags('Ingredients: Almonds, Sugar', ['Almonds', 'Sugar']);
    const treeNut = allergens.find((a) => a.name === 'tree_nuts');
    expect(treeNut).toMatchObject({ declared: false, provenance: 'ocr_detected' });
  });

  it('detects a vegetarian diet flag from the label word', () => {
    const { dietFlags } = parseAllergensAndDietFlags(SAMPLE_LABEL, []);
    expect(dietFlags).toContainEqual({ type: 'vegetarian', provenance: 'label_stated' });
  });

  it('does not confuse "non-vegetarian" with "vegetarian"', () => {
    const { dietFlags } = parseAllergensAndDietFlags('This product is Non-Vegetarian', []);
    expect(dietFlags).toContainEqual({ type: 'non_vegetarian', provenance: 'label_stated' });
    expect(dietFlags.find((f) => f.type === 'vegetarian')).toBeUndefined();
  });

  it('flags contains_gluten from ingredients when no explicit gluten-free claim exists', () => {
    const { dietFlags } = parseAllergensAndDietFlags('Ingredients: Wheat flour, Salt', ['Wheat flour', 'Salt']);
    expect(dietFlags).toContainEqual({ type: 'contains_gluten', provenance: 'ocr_detected' });
  });
});

describe('parseProductName', () => {
  it('picks the first plausible header line', () => {
    expect(parseProductName(SAMPLE_LABEL)).toBe('NALAM SNACKS');
  });
});

describe('parseLabel', () => {
  it('produces a high confidence score for a complete label', () => {
    const result = parseLabel(SAMPLE_LABEL);
    expect(result.extractionConfidence).toBeGreaterThanOrEqual(0.75);
    expect(result.productName).toBeTruthy();
    expect(result.ingredients.length).toBeGreaterThan(0);
    expect(result.allergens.length).toBeGreaterThan(0);
  });

  it('produces a low confidence score for sparse text', () => {
    const result = parseLabel('random text');
    expect(result.extractionConfidence).toBeLessThanOrEqual(0.25);
  });

  it('returns null instead of a nutrition-panel line or stray sentence when no real name is in frame', () => {
    // Regression: a photographed Nutrition Facts panel with no brand name visible, preceded by
    // incidental non-label text (e.g. transcribed webpage furniture) — the parser must not
    // guess a product name from either.
    const text = [
      'input from the public regarding ease of use.',
      'Nutrition Facts',
      '4 servings per container',
      'Serving size 1 1/2 cup (208g)',
      'Calories 240',
    ].join('\n');
    expect(parseProductName(text)).toBeNull();
  });
});
