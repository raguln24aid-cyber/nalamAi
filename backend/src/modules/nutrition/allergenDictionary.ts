/**
 * Maps ingredient-name keywords to a canonical allergen name. Used only to *infer* a possible
 * allergen from the ingredient list when the label has no explicit "Contains:" declaration.
 * Inferred matches are always surfaced with declared=false and softer, hedged language —
 * see docs/SAFETY_RULES.md rule 6.
 */
export const ALLERGEN_KEYWORDS: Record<string, string[]> = {
  milk: ['milk', 'milk solids', 'milk powder', 'casein', 'whey', 'butter', 'ghee', 'cream', 'lactose'],
  peanuts: ['peanut', 'groundnut'],
  tree_nuts: ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut', 'pecan', 'macadamia'],
  soy: ['soy', 'soya', 'soybean'],
  wheat: ['wheat', 'maida', 'atta', 'semolina', 'suji'],
  gluten: ['wheat', 'barley', 'rye', 'malt', 'maida'],
  egg: ['egg', 'albumen'],
  fish: ['fish', 'anchovy', 'tuna', 'salmon'],
  shellfish: ['shrimp', 'prawn', 'crab', 'lobster', 'shellfish'],
  sesame: ['sesame', 'til', 'gingelly'],
  mustard: ['mustard', 'rai'],
};

const GLUTEN_KEYWORDS = new Set(ALLERGEN_KEYWORDS.gluten);

export function findInferredAllergens(ingredients: string[]): string[] {
  const lowerIngredients = ingredients.map((i) => i.toLowerCase());
  const found = new Set<string>();

  for (const [allergen, keywords] of Object.entries(ALLERGEN_KEYWORDS)) {
    if (allergen === 'gluten') continue; // handled separately as a diet flag, not an allergen tag
    for (const ingredient of lowerIngredients) {
      if (keywords.some((kw) => ingredient.includes(kw))) {
        found.add(allergen);
        break;
      }
    }
  }
  return Array.from(found);
}

export function containsGluten(ingredients: string[]): boolean {
  const lowerIngredients = ingredients.map((i) => i.toLowerCase());
  return lowerIngredients.some((ingredient) =>
    Array.from(GLUTEN_KEYWORDS).some((kw) => ingredient.includes(kw)),
  );
}
