import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted on-device storage for the auth session (Android Keystore / iOS Keychain backed).
/// Never store tokens in shared_preferences or plain files — see ARCHITECTURE.md. The user
/// profile JSON stored here is small (id/email/preferredLanguage) and kept alongside the
/// tokens purely so the app can rehydrate a logged-in UI instantly on cold start without a
/// network round trip; it is not a substitute for the server-side profile.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'nalamai.accessToken';
  static const _refreshTokenKey = 'nalamai.refreshToken';
  static const _userJsonKey = 'nalamai.userJson';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userJson,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userJsonKey, value: jsonEncode(userJson)),
    ]);
  }

  Future<void> updateTokens({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<Map<String, dynamic>?> readUserJson() async {
    final raw = await _storage.read(key: _userJsonKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userJsonKey),
    ]);
  }
}
