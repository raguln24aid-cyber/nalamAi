import { TtsLanguage, TtsProvider } from './tts.provider';

/** Returns a tiny silent MP3-like buffer for tests/local dev (TTS_PROVIDER=mock). */
export class MockTtsProvider implements TtsProvider {
  async synthesize(_text: string, _language: TtsLanguage): Promise<Buffer> {
    return Buffer.from('mock-audio-bytes');
  }
}
