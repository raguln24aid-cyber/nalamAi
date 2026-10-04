import { loadConfig } from '../lib/config';
import { logger } from '../lib/logger';
import { BarcodeLookupError, BarcodeLookupProvider, BarcodeProductInfo } from './barcodeLookup.provider';

interface OpenFoodFactsResponse {
  status: number;
  product?: {
    product_name?: string;
    brands?: string;
    ingredients_text?: string;
    allergens_tags?: string[];
    labels_tags?: string[];
    serving_size?: string;
    nutriments?: Record<string, number | undefined>;
  };
}

function stripTagPrefix(tag: string): string {
  const idx = tag.indexOf(':');
  return idx >= 0 ? tag.slice(idx + 1).replace(/-/g, ' ') : tag;
}

export class OpenFoodFactsBarcodeProvider implements BarcodeLookupProvider {
  async lookup(barcode: string): Promise<BarcodeProductInfo | null> {
    const config = loadConfig();
    const url = `${config.OPEN_FOOD_FACTS_BASE_URL}/api/v2/product/${encodeURIComponent(barcode)}.json`;

    let response: Response;
    try {
      response = await fetch(url, {
        headers: { 'User-Agent': 'NalamAI/1.0 (accessibility food-label assistant)' },
      });
    } catch (err) {
      logger.error({ err, barcode }, 'Open Food Facts request failed');
      throw new BarcodeLookupError('Barcode lookup provider request failed');
    }

    // Open Food Facts returns HTTP 404 (not 200) for a barcode it simply doesn't have — that's
    // "not found", not a provider failure, so it must fall through to the status-body parsing
    // below rather than being thrown as an error. Only other non-2xx statuses are real failures.
    if (!response.ok && response.status !== 404) {
      throw new BarcodeLookupError(`Barcode lookup provider returned HTTP ${response.status}`);
    }

    const data = (await response.json()) as OpenFoodFactsResponse;
    if (data.status !== 1 || !data.product) {
      return null;
    }

    const p = data.product;
    const n = p.nutriments ?? {};

    return {
      barcode,
      name: p.product_name?.trim() || null,
      brand: p.brands?.split(',')[0]?.trim() || null,
      nutrition: {
        servingSize: p.serving_size ?? null,
        calories: n['energy-kcal_100g'] ?? null,
        sugarG: n['sugars_100g'] ?? null,
        proteinG: n['proteins_100g'] ?? null,
        fatG: n['fat_100g'] ?? null,
        saturatedFatG: n['saturated-fat_100g'] ?? null,
        sodiumMg: typeof n['sodium_100g'] === 'number' ? n['sodium_100g'] * 1000 : null,
        fiberG: n['fiber_100g'] ?? null,
      },
      ingredientsText: p.ingredients_text?.trim() || null,
      allergenTags: (p.allergens_tags ?? []).map(stripTagPrefix),
      labels: (p.labels_tags ?? []).map(stripTagPrefix),
    };
  }
}
