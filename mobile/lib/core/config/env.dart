import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to build-time configuration loaded from `.env` (see `.env.example`).
/// No provider API keys live here — the app only ever talks to our own backend, which
/// holds every third-party credential. See ARCHITECTURE.md.
class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:4000/api/v1');

  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');

  static bool get isProduction => environment == 'production';

  static bool get enableCloudTtsFallback =>
      dotenv.get('ENABLE_CLOUD_TTS_FALLBACK', fallback: 'true') == 'true';

  static bool get enableCloudSttFallback =>
      dotenv.get('ENABLE_CLOUD_STT_FALLBACK', fallback: 'false') == 'true';

  static String get defaultLanguage => dotenv.get('DEFAULT_LANGUAGE', fallback: 'auto');
}
