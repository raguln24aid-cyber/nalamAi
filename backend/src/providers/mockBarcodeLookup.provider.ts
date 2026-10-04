import { BarcodeLookupProvider, BarcodeProductInfo } from './barcodeLookup.provider';

export class MockBarcodeLookupProvider implements BarcodeLookupProvider {
  async lookup(barcode: string): Promise<BarcodeProductInfo | null> {
    if (barcode === '0000000000000') return null; // simulate "not found" for tests
    return {
      barcode,
      name: 'Mock Multigrain Biscuits',
      brand: 'NalamAI Test Foods',
      nutrition: {
        servingSize: '30g',
        calories: 140,
        sugarG: 5,
        proteinG: 3,
        fatG: 6,
        saturatedFatG: 2.5,
        sodiumMg: 120,
        fiberG: 2,
      },
      ingredientsText: 'Whole wheat flour, sugar, palm oil, milk solids, salt, raising agents',
      allergenTags: ['milk', 'wheat'],
      labels: ['vegetarian'],
    };
  }
}
