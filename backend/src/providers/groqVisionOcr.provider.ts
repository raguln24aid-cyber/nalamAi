import { loadConfig } from '../lib/config';
import { logger } from '../lib/logger';
import { OcrProvider, OcrProviderError, OcrResult } from './ocr.provider';

interface GroqChatResponse {
  choices?: { message?: { content?: string } }[];
  error?: { message?: string };
}

const TRANSCRIBE_PROMPT = `You are a strict OCR transcription tool, not a conversational assistant. Read every piece of
text visible on this food product label photo and output it verbatim, preserving line breaks
and the original wording — do not summarize, translate, correct spelling, or add any commentary.
Include the product name, nutrition table, ingredient list, allergen statements, and any other
printed text you can see. The text may be in English, Tamil, or a mix of both — transcribe it
exactly as printed, in its original script.

Accuracy rules, in priority order:
1. Numbers matter most — this is nutrition data. Read every digit in the nutrition table
   carefully (calories, grams, milligrams, percentages) and double-check each one before
   outputting it. A misread digit here is worse than a misread word elsewhere.
2. Keep each nutrition line on its own line, in the format printed on the label (e.g.
   "Sodium 430mg", "Total Sugars 4g") — do not merge multiple facts onto one line or reformat
   the table.
3. If a character or digit is genuinely illegible (blurry, cut off, glare), transcribe your best
   reading rather than skipping it — never silently omit a value you can partially see.
4. Never invent, assume, or add any text that is not visibly printed in the photo. Never add an
   introductory phrase like "Here is the text:" or any closing remark — output ONLY the
   transcription itself, starting directly with the first word on the label.
5. If the image contains no readable text at all, output exactly: NO_TEXT_FOUND`;

/**
 * Uses a Groq-hosted vision-capable model as an OCR substitute (see docs comment on
 * GroqAiProvider re: Groq vs xAI "Grok" naming). The model's raw transcription is fed into the
 * same modules/nutrition/labelParser.ts regex pipeline used for the Google Vision path, so all
 * downstream parsing/provenance logic is shared and unchanged.
 */
export class GroqVisionOcrProvider implements OcrProvider {
  async extractText(imageBuffer: Buffer): Promise<OcrResult> {
    const config = loadConfig();
    const dataUrl = `data:image/jpeg;base64,${imageBuffer.toString('base64')}`;

    let response: Response;
    try {
      response = await fetch(`${config.GROQ_BASE_URL}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${config.GROQ_API_KEY}`,
        },
        body: JSON.stringify({
          model: config.GROQ_VISION_MODEL,
          // Kept under 1000: this account's on-demand tier enforces a 1000 output-tokens-per-
          // minute cap per request for this model — 1024 was observed to 429 in testing.
          max_tokens: 900,
          temperature: 0,
          messages: [
            {
              role: 'user',
              content: [
                { type: 'text', text: TRANSCRIBE_PROMPT },
                { type: 'image_url', image_url: { url: dataUrl } },
              ],
            },
          ],
        }),
      });
    } catch (err) {
      logger.error({ err }, 'Groq vision OCR request failed');
      throw new OcrProviderError('OCR provider request failed');
    }

    const data = (await response.json()) as GroqChatResponse;

    if (!response.ok) {
      logger.error({ status: response.status, error: data.error }, 'Groq vision API returned an error');
      throw new OcrProviderError(data.error?.message ?? 'OCR provider request failed');
    }

    const text = data.choices?.[0]?.message?.content?.trim() ?? '';
    if (!text || text === 'NO_TEXT_FOUND') {
      return { fullText: '', blocks: [], confidence: null, detectedLanguages: [] };
    }

    const hasTamil = /[஀-௿]/.test(text);
    return {
      fullText: text,
      blocks: text.split('\n').map((line) => ({ text: line, confidence: null })),
      confidence: null,
      detectedLanguages: hasTamil ? ['ta'] : ['en'],
    };
  }
}
