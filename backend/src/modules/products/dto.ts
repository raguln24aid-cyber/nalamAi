import { Allergen, DietFlag, Ingredient, NutritionFact, Product, SafetyFlag, Scan } from '@prisma/client';

export type ProductWithRelations = Product & {
  nutritionFacts: NutritionFact | null;
  ingredients: Ingredient[];
  allergens: Allergen[];
  dietFlags: DietFlag[];
};

export type ScanWithRelations = Scan & {
  product: ProductWithRelations | null;
  safetyFlags: SafetyFlag[];
};

export function toProductDto(product: ProductWithRelations | null) {
  if (!product) return null;
  return {
    id: product.id,
    barcode: product.barcode,
    name: product.name,
    brand: product.brand,
    nutritionFacts: product.nutritionFacts
      ? {
          servingSize: product.nutritionFacts.servingSize,
          calories: product.nutritionFacts.calories,
          sugarG: product.nutritionFacts.sugarG,
          proteinG: product.nutritionFacts.proteinG,
          fatG: product.nutritionFacts.fatG,
          saturatedFatG: product.nutritionFacts.saturatedFatG,
          sodiumMg: product.nutritionFacts.sodiumMg,
          fiberG: product.nutritionFacts.fiberG,
          provenance: product.nutritionFacts.provenance,
        }
      : null,
    ingredients: product.ingredients
      .sort((a, b) => a.position - b.position)
      .map((i) => ({ name: i.name, position: i.position, provenance: i.provenance })),
    allergens: product.allergens.map((a) => ({
      name: a.name,
      declared: a.declared,
      provenance: a.provenance,
    })),
    dietFlags: product.dietFlags.map((d) => ({ type: d.type, provenance: d.provenance })),
  };
}

export function toScanDto(scan: ScanWithRelations) {
  return {
    scanId: scan.id,
    status: scan.status,
    product: toProductDto(scan.product),
    safetyFlags: scan.safetyFlags.map((f) => ({
      type: f.type,
      severity: f.severity,
      message: f.message,
      provenance: f.provenance,
    })),
    languageDetected: scan.languageDetected,
    errorMessage: scan.errorMessage,
    createdAt: scan.createdAt,
  };
}

export function toScanSummaryDto(scan: ScanWithRelations) {
  return {
    scanId: scan.id,
    status: scan.status,
    productName: scan.product?.name ?? null,
    brand: scan.product?.brand ?? null,
    hasCriticalSafetyFlag: scan.safetyFlags.some((f) => f.severity === 'critical'),
    createdAt: scan.createdAt,
  };
}

export const PRODUCT_INCLUDE = {
  nutritionFacts: true,
  ingredients: true,
  allergens: true,
  dietFlags: true,
} as const;

export const SCAN_INCLUDE = {
  product: { include: PRODUCT_INCLUDE },
  safetyFlags: true,
} as const;
