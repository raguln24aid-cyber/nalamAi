import { OcrProvider, OcrResult } from './ocr.provider';

/**
 * Deterministic fake used in tests and local dev without cloud credentials
 * (OCR_PROVIDER=mock). Returns a fixed label so integration tests are reproducible.
 */
export class MockOcrProvider implements OcrProvider {
  async extractText(_imageBuffer: Buffer): Promise<OcrResult> {
    const fullText = [
      'NALAM SNACKS',
      'Roasted Peanut Mix',
      'Nutrition Information (per 100g)',
      'Energy 520 kcal',
      'Protein 18g',
      'Total Fat 42g',
      'Saturated Fat 8g',
      'Total Sugars 6g',
      'Sodium 380mg',
      'Dietary Fibre 7g',
      'Ingredients: Peanuts, Refined Palm Oil, Salt, Sugar, Milk Solids, Spices',
      'Contains: Peanuts, Milk',
      'Vegetarian',
    ].join('\n');

    return {
      fullText,
      blocks: fullText.split('\n').map((text) => ({ text, confidence: 0.95 })),
      confidence: 0.95,
      detectedLanguages: ['en'],
    };
  }
}
