export type TtsLanguage = 'en' | 'ta';

export class TtsProviderError extends Error {}

/** Abstraction over any cloud TTS backend, used only as a fallback to on-device TTS. */
export interface TtsProvider {
  synthesize(text: string, language: TtsLanguage): Promise<Buffer>;
}
