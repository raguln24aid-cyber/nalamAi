/// On-device mirror of the backend's `detectLanguage` heuristic
/// (backend/src/modules/assistant/languageDetector.ts). Used to pick a TTS voice or route a
/// voice command locally before the round trip to the backend, which remains the authoritative
/// detector for AI Assistant responses. Keep the two heuristics in sync if either changes.
class LanguageHint {
  LanguageHint._();

  static final RegExp _tamilScript = RegExp(r'[஀-௿]');

  static const _tanglishMarkers = [
    'pannu', 'panna', 'irukka', 'irukku', 'enna', 'yenna', 'ithu', 'idhu', 'intha', 'antha',
    'vera', 'venum', 'illa', 'illai', 'sapdu', 'sapdalam', 'sollu', 'solla', 'padikanum',
    'ungal', 'unga', 'nalla', 'romba', 'seekiram', 'poitu', 'irukkuma', 'irundha', 'kondu',
    'evlo', 'ethana', 'porulai', 'porul',
  ];

  /// Returns 'en' or 'ta'.
  static String detect(String text) {
    if (_tamilScript.hasMatch(text)) return 'ta';
    final lower = text.toLowerCase();
    if (_tanglishMarkers.any(lower.contains)) return 'ta';
    return 'en';
  }
}
