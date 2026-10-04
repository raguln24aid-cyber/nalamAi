import { loadConfig } from '../lib/config';
import { OcrProvider } from './ocr.provider';
import { GoogleVisionOcrProvider } from './googleVisionOcr.provider';
import { GroqVisionOcrProvider } from './groqVisionOcr.provider';
import { MockOcrProvider } from './mockOcr.provider';
import { BarcodeLookupProvider } from './barcodeLookup.provider';
import { OpenFoodFactsBarcodeProvider } from './openFoodFactsBarcode.provider';
import { MockBarcodeLookupProvider } from './mockBarcodeLookup.provider';
import { AiProvider } from './ai.provider';
import { AnthropicAiProvider } from './anthropicAi.provider';
import { GroqAiProvider } from './groqAi.provider';
import { MockAiProvider } from './mockAi.provider';
import { TtsProvider } from './tts.provider';
import { GoogleCloudTtsProvider } from './googleCloudTts.provider';
import { MockTtsProvider } from './mockTts.provider';

let ocrProvider: OcrProvider | null = null;
let barcodeProvider: BarcodeLookupProvider | null = null;
let aiProvider: AiProvider | null = null;
let ttsProvider: TtsProvider | null = null;

export function getOcrProvider(): OcrProvider {
  if (!ocrProvider) {
    const config = loadConfig();
    ocrProvider =
      config.OCR_PROVIDER === 'mock'
        ? new MockOcrProvider()
        : config.OCR_PROVIDER === 'groq'
          ? new GroqVisionOcrProvider()
          : new GoogleVisionOcrProvider();
  }
  return ocrProvider;
}

export function getBarcodeLookupProvider(): BarcodeLookupProvider {
  if (!barcodeProvider) {
    const config = loadConfig();
    barcodeProvider =
      config.BARCODE_PROVIDER === 'mock' ? new MockBarcodeLookupProvider() : new OpenFoodFactsBarcodeProvider();
  }
  return barcodeProvider;
}

export function getAiProvider(): AiProvider {
  if (!aiProvider) {
    const config = loadConfig();
    aiProvider =
      config.AI_PROVIDER === 'mock'
        ? new MockAiProvider()
        : config.AI_PROVIDER === 'groq'
          ? new GroqAiProvider()
          : new AnthropicAiProvider();
  }
  return aiProvider;
}

export function getTtsProvider(): TtsProvider {
  if (!ttsProvider) {
    const config = loadConfig();
    ttsProvider = config.TTS_PROVIDER === 'mock' ? new MockTtsProvider() : new GoogleCloudTtsProvider();
  }
  return ttsProvider;
}
