import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/settings_storage.dart';

/// 'auto' | 'en' | 'ta' — drives both the app's visual locale (MaterialApp) and which language
/// voice input/output default to. 'auto' means: detect per-utterance (backend for AI answers,
/// LanguageHint on-device for local strings) rather than pin to one language app-wide.
class LocaleController extends StateNotifier<String> {
  LocaleController(this._settingsStorage) : super('auto') {
    _restore();
  }

  final SettingsStorage _settingsStorage;

  Future<void> _restore() async {
    state = await _settingsStorage.getLanguage();
  }

  Future<void> setLanguage(String language) async {
    state = language;
    await _settingsStorage.setLanguage(language);
  }

  /// The concrete Locale to pass to MaterialApp. Falls back to English visuals when 'auto' —
  /// spoken responses still auto-detect per the product spec; the app chrome needs one locale.
  Locale get effectiveLocale => switch (state) {
        'ta' => const Locale('ta'),
        _ => const Locale('en'),
      };
}

final localeControllerProvider = StateNotifierProvider<LocaleController, String>((ref) {
  return LocaleController(ref.watch(settingsStorageProvider));
});
