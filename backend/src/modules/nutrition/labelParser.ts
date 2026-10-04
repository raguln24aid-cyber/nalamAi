import { containsGluten, findInferredAllergens } from './allergenDictionary';

export type ProvenanceSource = 'label_stated' | 'ocr_detected' | 'ai_interpreted' | 'unverified';

export interface ParsedNutrition {
  servingSize: string | null;
  calories: number | null;
  sugarG: number | null;
  proteinG: number | null;
  fatG: number | null;
  saturatedFatG: number | null;
  sodiumMg: number | null;
  fiberG: number | null;
  provenance: ProvenanceSource;
}

export interface ParsedAllergen {
  name: string;
  declared: boolean;
  provenance: ProvenanceSource;
}

export interface ParsedDietFlag {
  type: 'vegetarian' | 'non_vegetarian' | 'vegan' | 'gluten_free' | 'contains_gluten';
  provenance: ProvenanceSource;
}

export interface ParsedLabel {
  productName: string | null;
  nutrition: ParsedNutrition;
  ingredients: string[];
  allergens: ParsedAllergen[];
  dietFlags: ParsedDietFlag[];
  extractionConfidence: number;
}

/** number possibly followed by a unit, e.g. "520 kcal", "18g", "380 mg" */
function findNumberNear(text: string, labelPatterns: RegExp[]): number | null {
  for (const pattern of labelPatterns) {
    const match = pattern.exec(text);
    if (match?.[1]) {
      const value = parseFloat(match[1].replace(/,/g, ''));
      if (!Number.isNaN(value)) return value;
    }
  }
  return null;
}

export function parseNutrition(text: string): ParsedNutrition {
  const calories = findNumberNear(text, [
    /energy[^\d]{0,15}(\d+(?:\.\d+)?)\s*kcal/i,
    /calories[^\d]{0,15}(\d+(?:\.\d+)?)/i,
  ]);
  const sugarG = findNumberNear(text, [/(?:total\s+)?sugars?[^\d]{0,10}(\d+(?:\.\d+)?)\s*g/i]);
  const proteinG = findNumberNear(text, [/protein[^\d]{0,10}(\d+(?:\.\d+)?)\s*g/i]);
  const saturatedFatG = findNumberNear(text, [/saturated\s+fat[^\d]{0,10}(\d+(?:\.\d+)?)\s*g/i]);
  const fatG = findNumberNear(text, [/^(?:total\s+)?fat[^\d]{0,10}(\d+(?:\.\d+)?)\s*g/im]);
  const sodiumMg = findNumberNear(text, [
    /sodium[^\d]{0,10}(\d+(?:\.\d+)?)\s*mg/i,
    /salt[^\d]{0,10}(\d+(?:\.\d+)?)\s*g/i, // salt in g is a common alt to sodium in mg
  ]);
  const fiberG = findNumberNear(text, [/(?:dietary\s+)?fib(?:re|er)[^\d]{0,10}(\d+(?:\.\d+)?)\s*g/i]);

  const servingSizeMatch = /(?:per|serving size)[:\s]*(\d+(?:\.\d+)?\s*(?:g|ml))/i.exec(text);

  const fieldsFound = [calories, sugarG, proteinG, fatG, saturatedFatG, sodiumMg, fiberG].filter(
    (v) => v !== null,
  ).length;

  return {
    servingSize: servingSizeMatch?.[1] ?? null,
    calories,
    sugarG,
    proteinG,
    fatG,
    saturatedFatG,
    sodiumMg,
    fiberG,
    provenance: fieldsFound > 0 ? 'ocr_detected' : 'unverified',
  };
}

export function parseIngredients(text: string): string[] {
  const match = /ingredients?\s*[:-]\s*(.+?)(?:\n\s*\n|contains\s*:|allerg|nutrition|$)/is.exec(text);
  if (!match?.[1]) return [];

  return match[1]
    .split(/\n|,/)
    .map((s) => s.trim().replace(/\.$/, ''))
    .filter((s) => s.length > 0 && s.length < 100);
}

export function parseAllergensAndDietFlags(
  text: string,
  ingredients: string[],
): { allergens: ParsedAllergen[]; dietFlags: ParsedDietFlag[] } {
  const allergens: ParsedAllergen[] = [];
  const seen = new Set<string>();

  // Explicit "Contains: X, Y" declaration — highest confidence, verbatim from the label.
  const containsMatch = /contains\s*[:-]\s*(.+?)(?:\n|$)/i.exec(text);
  if (containsMatch?.[1]) {
    const declaredAllergens = containsMatch[1]
      .split(',')
      .map((s) => s.trim().toLowerCase().replace(/\.$/, ''))
      .filter(Boolean);
    for (const name of declaredAllergens) {
      if (!seen.has(name)) {
        allergens.push({ name, declared: true, provenance: 'label_stated' });
        seen.add(name);
      }
    }
  }

  // Inferred from ingredient keyword matching — lower confidence, explicitly not "declared".
  for (const name of findInferredAllergens(ingredients)) {
    if (!seen.has(name)) {
      allergens.push({ name, declared: false, provenance: 'ocr_detected' });
      seen.add(name);
    }
  }

  const dietFlags: ParsedDietFlag[] = [];
  const lowerText = text.toLowerCase();
  const hasNonVegMarker = /\bnon[\s-]?vegetarian\b/i.test(text);
  const hasVeganMarker = /\bvegan\b/i.test(text);
  const hasVegMarker = !hasNonVegMarker && /\bvegetarian\b/i.test(text);

  if (hasVeganMarker) dietFlags.push({ type: 'vegan', provenance: 'label_stated' });
  if (hasVegMarker) dietFlags.push({ type: 'vegetarian', provenance: 'label_stated' });
  if (hasNonVegMarker) dietFlags.push({ type: 'non_vegetarian', provenance: 'label_stated' });

  if (/gluten[\s-]?free/i.test(lowerText)) {
    dietFlags.push({ type: 'gluten_free', provenance: 'label_stated' });
  } else if (ingredients.length > 0 && containsGluten(ingredients)) {
    dietFlags.push({ type: 'contains_gluten', provenance: 'ocr_detected' });
  }

  return { allergens, dietFlags };
}

const PRODUCT_NAME_NOISE =
  /nutrition|ingredients|contains|serving|per container|amount per|daily value|calories/i;

export function parseProductName(text: string): string | null {
  const lines = text
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);
  // Heuristic: the first non-trivial line before any nutrition/ingredients section is usually
  // the brand/product name printed at the top of a label. Guard against two common false
  // positives: (1) a full prose sentence — e.g. incidental page/footnote text an OCR/vision
  // model transcribed faithfully from a photographed webpage rather than a real package — which
  // a product name never is, and (2) nutrition-panel furniture (serving size, daily value, etc.)
  // that happens to appear in the first few lines when no name is visible in frame at all. When
  // nothing plausible is found, return null rather than guessing — see docs/SAFETY_RULES.md:
  // an absent fact must stay "unverified", never be replaced with a confident-looking guess.
  for (const line of lines.slice(0, 4)) {
    const wordCount = line.split(/\s+/).filter(Boolean).length;
    const looksLikeSentence = /[.!?]$/.test(line) && wordCount >= 5;
    const startsWithDigit = /^\d/.test(line);

    if (
      line.length >= 3 &&
      line.length <= 60 &&
      wordCount <= 8 &&
      !looksLikeSentence &&
      !startsWithDigit &&
      !PRODUCT_NAME_NOISE.test(line)
    ) {
      return line;
    }
  }
  return null;
}

export function parseLabel(rawText: string): ParsedLabel {
  const nutrition = parseNutrition(rawText);
  const ingredients = parseIngredients(rawText);
  const { allergens, dietFlags } = parseAllergensAndDietFlags(rawText, ingredients);
  const productName = parseProductName(rawText);

  const signals = [
    productName !== null,
    nutrition.provenance !== 'unverified',
    ingredients.length > 0,
    allergens.length > 0,
  ].filter(Boolean).length;

  return {
    productName,
    nutrition,
    ingredients,
    allergens,
    dietFlags,
    extractionConfidence: signals / 4,
  };
}
