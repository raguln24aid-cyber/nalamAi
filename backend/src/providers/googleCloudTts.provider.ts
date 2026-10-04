import textToSpeech from '@google-cloud/text-to-speech';
import { loadConfig } from '../lib/config';
import { logger } from '../lib/logger';
import { TtsLanguage, TtsProvider, TtsProviderError } from './tts.provider';

const VOICE_BY_LANGUAGE: Record<TtsLanguage, { languageCode: string; name: string }> = {
  en: { languageCode: 'en-IN', name: 'en-IN-Wavenet-D' },
  ta: { languageCode: 'ta-IN', name: 'ta-IN-Wavenet-A' },
};

function loadCredentials(): Record<string, unknown> | undefined {
  const config = loadConfig();
  if (!config.GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE64) return undefined;
  const json = Buffer.from(config.GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE64, 'base64').toString('utf-8');
  return JSON.parse(json);
}

export class GoogleCloudTtsProvider implements TtsProvider {
  private client: InstanceType<typeof textToSpeech.TextToSpeechClient>;

  constructor() {
    const credentials = loadCredentials();
    this.client = new textToSpeech.TextToSpeechClient(
      credentials ? { credentials: credentials as Record<string, string> } : undefined,
    );
  }

  async synthesize(text: string, language: TtsLanguage): Promise<Buffer> {
    const voice = VOICE_BY_LANGUAGE[language];
    try {
      const [response] = await this.client.synthesizeSpeech({
        input: { text },
        voice: { languageCode: voice.languageCode, name: voice.name },
        audioConfig: { audioEncoding: 'MP3' },
      });
      if (!response.audioContent) {
        throw new TtsProviderError('TTS provider returned no audio content');
      }
      return Buffer.from(response.audioContent as Uint8Array);
    } catch (err) {
      if (err instanceof TtsProviderError) throw err;
      logger.error({ err, language }, 'Google Cloud TTS request failed');
      throw new TtsProviderError('TTS provider request failed');
    }
  }
}
