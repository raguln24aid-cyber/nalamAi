export interface BarcodeProductInfo {
  barcode: string;
  name: string | null;
  brand: string | null;
  nutrition: {
    servingSize: string | null;
    calories: number | null;
    sugarG: number | null;
    proteinG: number | null;
    fatG: number | null;
    saturatedFatG: number | null;
    sodiumMg: number | null;
    fiberG: number | null;
  } | null;
  ingredientsText: string | null;
  allergenTags: string[];
  /** true if this open database explicitly labels the product vegetarian/vegan, else null. */
  labels: string[];
}

export class BarcodeLookupError extends Error {}

/** Abstraction over any barcode → product database lookup (BARCODE_PROVIDER env var). */
export interface BarcodeLookupProvider {
  lookup(barcode: string): Promise<BarcodeProductInfo | null>;
}
