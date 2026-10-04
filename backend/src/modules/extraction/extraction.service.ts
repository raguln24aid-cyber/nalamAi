import { prisma } from '../../lib/prisma';
import { AppError } from '../../lib/errors';
import { logger } from '../../lib/logger';
import { getBarcodeLookupProvider, getOcrProvider } from '../../providers';
import { OcrProviderError } from '../../providers/ocr.provider';
import { BarcodeLookupError } from '../../providers/barcodeLookup.provider';
import { parseLabel } from '../nutrition/labelParser';
import { analyzeSafety } from '../safety/safetyAnalyzer';
import { PRODUCT_INCLUDE, SCAN_INCLUDE, toScanDto } from '../products/dto';
import { CreateScanInput } from './schemas';
import type { DietFlagType, Prisma, ProvenanceSource } from '@prisma/client';

const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

interface BuiltProductData {
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
    provenance: ProvenanceSource;
  } | null;
  ingredients: { name: string; provenance: ProvenanceSource }[];
  allergens: { name: string; declared: boolean; provenance: ProvenanceSource }[];
  dietFlags: { type: DietFlagType; provenance: ProvenanceSource }[];
  rawOcrText: string | null;
  extractionConfidence: number;
  languageDetected: 'en' | 'ta' | null;
}

async function buildFromBarcode(barcode: string): Promise<BuiltProductData | null> {
  const provider = getBarcodeLookupProvider();
  let info;
  try {
    info = await provider.lookup(barcode);
  } catch (err) {
    if (err instanceof BarcodeLookupError) {
      throw new AppError('PROVIDER_UNAVAILABLE', 'Barcode lookup service is temporarily unavailable');
    }
    throw err;
  }
  if (!info) return null;

  return {
    name: info.name,
    brand: info.brand,
    nutrition: info.nutrition ? { ...info.nutrition, provenance: 'label_stated' } : null,
    ingredients: info.ingredientsText
      ? info.ingredientsText
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean)
          .map((name) => ({ name, provenance: 'label_stated' as ProvenanceSource }))
      : [],
    allergens: info.allergenTags.map((name) => ({
      name,
      declared: true,
      provenance: 'label_stated' as ProvenanceSource,
    })),
    dietFlags: info.labels
      .filter((l) => ['vegetarian', 'vegan', 'gluten free'].includes(l.toLowerCase()))
      .map((l) => ({
        type: (l.toLowerCase() === 'gluten free' ? 'gluten_free' : l.toLowerCase()) as DietFlagType,
        provenance: 'label_stated' as ProvenanceSource,
      })),
    rawOcrText: null,
    extractionConfidence: 0.9,
    languageDetected: null,
  };
}

async function buildFromImage(imageBase64: string): Promise<BuiltProductData> {
  const buffer = Buffer.from(imageBase64, 'base64');
  if (buffer.byteLength === 0) {
    throw new AppError('VALIDATION_ERROR', 'imageBase64 could not be decoded');
  }
  if (buffer.byteLength > MAX_IMAGE_BYTES) {
    throw new AppError('VALIDATION_ERROR', 'Image exceeds the 6MB size limit');
  }

  const ocr = getOcrProvider();
  let result;
  try {
    result = await ocr.extractText(buffer);
  } catch (err) {
    if (err instanceof OcrProviderError) {
      throw new AppError('PROVIDER_UNAVAILABLE', 'OCR service is temporarily unavailable');
    }
    throw err;
  }

  if (!result.fullText.trim()) {
    throw new AppError('EXTRACTION_FAILED', 'No text could be detected in the image', {
      reason: 'no_text_detected',
    });
  }

  const parsed = parseLabel(result.fullText);
  const languageDetected: 'en' | 'ta' | null = result.detectedLanguages.includes('ta') ? 'ta' : 'en';

  return {
    name: parsed.productName,
    brand: null,
    nutrition: parsed.nutrition,
    ingredients: parsed.ingredients.map((name) => ({ name, provenance: 'ocr_detected' as ProvenanceSource })),
    allergens: parsed.allergens,
    dietFlags: parsed.dietFlags,
    rawOcrText: result.fullText,
    extractionConfidence: parsed.extractionConfidence,
    languageDetected,
  };
}

function mergeProductData(barcodeData: BuiltProductData | null, ocrData: BuiltProductData | null): BuiltProductData {
  if (barcodeData && !ocrData) return barcodeData;
  if (ocrData && !barcodeData) return ocrData;
  if (!barcodeData && !ocrData) {
    throw new AppError('EXTRACTION_FAILED', 'Could not extract any product information', {
      reason: 'barcode_not_found',
    });
  }
  // Both present: prefer barcode data (structured, higher trust) but fill gaps from OCR.
  const b = barcodeData!;
  const o = ocrData!;
  return {
    name: b.name ?? o.name,
    brand: b.brand ?? o.brand,
    nutrition: b.nutrition ?? o.nutrition,
    ingredients: b.ingredients.length > 0 ? b.ingredients : o.ingredients,
    allergens: b.allergens.length > 0 ? b.allergens : o.allergens,
    dietFlags: b.dietFlags.length > 0 ? b.dietFlags : o.dietFlags,
    rawOcrText: o.rawOcrText,
    extractionConfidence: Math.max(b.extractionConfidence, o.extractionConfidence),
    languageDetected: o.languageDetected,
  };
}

async function upsertProduct(barcode: string | undefined, data: BuiltProductData) {
  if (barcode) {
    const existing = await prisma.product.findUnique({
      where: { barcode },
      include: PRODUCT_INCLUDE,
    });
    if (existing) return existing;
  }

  const createData: Prisma.ProductCreateInput = {
    barcode: barcode ?? null,
    name: data.name,
    brand: data.brand,
    nutritionFacts: data.nutrition ? { create: data.nutrition } : undefined,
    ingredients: {
      create: data.ingredients.map((i, idx) => ({ name: i.name, position: idx, provenance: i.provenance })),
    },
    allergens: { create: data.allergens },
    dietFlags: { create: data.dietFlags },
  };

  return prisma.product.create({ data: createData, include: PRODUCT_INCLUDE });
}

export async function processScan(userId: string, input: CreateScanInput) {
  let barcodeData: BuiltProductData | null = null;
  let ocrData: BuiltProductData | null = null;

  if (input.barcode) {
    barcodeData = await buildFromBarcode(input.barcode);
  }
  if (input.imageBase64) {
    ocrData = await buildFromImage(input.imageBase64);
  }

  const merged = mergeProductData(barcodeData, ocrData);
  const product = await upsertProduct(input.barcode, merged);

  const userAllergies = await prisma.allergy.findMany({ where: { userId } });

  const safetyDrafts = analyzeSafety({
    productAllergens: product.allergens.map((a) => ({ name: a.name, declared: a.declared })),
    nutrition: {
      sugarG: product.nutritionFacts?.sugarG ?? null,
      saturatedFatG: product.nutritionFacts?.saturatedFatG ?? null,
      sodiumMg: product.nutritionFacts?.sodiumMg ?? null,
    },
    userAllergies: userAllergies.map((a) => ({ allergen: a.allergen, severity: a.severity })),
  });

  const scan = await prisma.scan.create({
    data: {
      userId,
      productId: product.id,
      status: 'completed',
      languageDetected: merged.languageDetected,
      rawOcrText: merged.rawOcrText,
      extractionConfidence: merged.extractionConfidence,
      safetyFlags: { create: safetyDrafts },
    },
    include: SCAN_INCLUDE,
  });

  logger.info({ scanId: scan.id, userId, productId: product.id }, 'Scan completed');
  return toScanDto(scan);
}
