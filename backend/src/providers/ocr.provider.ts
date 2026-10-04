export interface OcrTextBlock {
  text: string;
  confidence: number | null;
}

export interface OcrResult {
  /** Full concatenated text, in reading order, as best Vision can determine. */
  fullText: string;
  blocks: OcrTextBlock[];
  /** Overall detection confidence, 0..1, when the provider exposes one. */
  confidence: number | null;
  /** ISO 639-1 language code(s) the provider believes the text is in. */
  detectedLanguages: string[];
}

/** Thrown when the provider itself can't process the image (network/quota/etc — not "no text found"). */
export class OcrProviderError extends Error {}

/**
 * Abstraction over any OCR/vision backend. Swap implementations via OCR_PROVIDER env var
 * without touching calling code (modules/extraction).
 */
export interface OcrProvider {
  extractText(imageBuffer: Buffer): Promise<OcrResult>;
}
