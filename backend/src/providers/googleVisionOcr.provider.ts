import vision from '@google-cloud/vision';
import { OcrProvider, OcrProviderError, OcrResult } from './ocr.provider';
import { loadConfig } from '../lib/config';
import { logger } from '../lib/logger';

function loadCredentials(): Record<string, unknown> | undefined {
  const config = loadConfig();
  if (!config.GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE64) return undefined;
  const json = Buffer.from(config.GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE64, 'base64').toString('utf-8');
  return JSON.parse(json);
}

export class GoogleVisionOcrProvider implements OcrProvider {
  private client: InstanceType<typeof vision.ImageAnnotatorClient>;

  constructor() {
    const credentials = loadCredentials();
    this.client = new vision.ImageAnnotatorClient(
      credentials ? { credentials: credentials as Record<string, string> } : undefined,
    );
  }

  async extractText(imageBuffer: Buffer): Promise<OcrResult> {
    try {
      const [result] = await this.client.documentTextDetection({
        image: { content: imageBuffer },
      });

      const annotation = result.fullTextAnnotation;
      if (!annotation?.text) {
        return { fullText: '', blocks: [], confidence: null, detectedLanguages: [] };
      }

      const blocks: { text: string; confidence: number | null }[] = [];
      const languages = new Set<string>();
      let confidenceSum = 0;
      let confidenceCount = 0;

      for (const page of annotation.pages ?? []) {
        for (const detectedLang of page.property?.detectedLanguages ?? []) {
          if (detectedLang.languageCode) languages.add(detectedLang.languageCode);
        }
        for (const block of page.blocks ?? []) {
          const text = (block.paragraphs ?? [])
            .map((p) =>
              (p.words ?? [])
                .map((w) => (w.symbols ?? []).map((s) => s.text ?? '').join(''))
                .join(' '),
            )
            .join('\n');
          if (text.trim()) {
            blocks.push({ text, confidence: block.confidence ?? null });
            if (typeof block.confidence === 'number') {
              confidenceSum += block.confidence;
              confidenceCount += 1;
            }
          }
        }
      }

      return {
        fullText: annotation.text,
        blocks,
        confidence: confidenceCount > 0 ? confidenceSum / confidenceCount : null,
        detectedLanguages: Array.from(languages),
      };
    } catch (err) {
      logger.error({ err }, 'Google Vision OCR request failed');
      throw new OcrProviderError('OCR provider request failed');
    }
  }
}
