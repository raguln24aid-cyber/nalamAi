import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive user preferences (language, haptics, cloud-voice opt-in). Safe for plain
/// shared_preferences — nothing here is a credential or personal health data.
class SettingsStorage {
  SettingsStorage({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  Future<SharedPreferences> get _prefs async => _prefsOverride ?? SharedPreferences.getInstance();

  static const _languageKey = 'nalamai.language'; // 'en' | 'ta' | 'auto'
  static const _hapticsKey = 'nalamai.hapticsEnabled';
  static const _cloudTtsKey = 'nalamai.cloudTtsFallbackEnabled';
  static const _signedOutKey = 'nalamai.signedOutDeliberately';

  Future<String> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_languageKey) ?? 'auto';
  }

  Future<void> setLanguage(String language) async {
    final prefs = await _prefs;
    await prefs.setString(_languageKey, language);
  }

  Future<bool> getHapticsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_hapticsKey) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_hapticsKey, enabled);
  }

  Future<bool> getCloudTtsFallbackEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_cloudTtsKey) ?? true;
  }

  Future<void> setCloudTtsFallbackEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_cloudTtsKey, enabled);
  }

  /// True once the user has explicitly said "log out". Sign-in is otherwise automatic from the
  /// device credentials (see DeviceAccountStore), so without this flag a logout would be undone
  /// by the very next auto sign-in and the command would look broken.
  Future<bool> getSignedOutDeliberately() async {
    final prefs = await _prefs;
    return prefs.getBool(_signedOutKey) ?? false;
  }

  Future<void> setSignedOutDeliberately(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_signedOutKey, value);
  }
}
