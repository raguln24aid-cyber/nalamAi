import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The credentials of the account this device owns. Generated on first run and never shown to
/// or typed by the user.
class DeviceCredentials {
  const DeviceCredentials({required this.email, required this.password});
  final String email;
  final String password;
}

/// Backs the app's zero-typing sign-in.
///
/// Email + password auth is unusable for our primary user: a blind person cannot reliably type
/// an address into a form, and spelling a password out loud is both error-prone and a privacy
/// leak in any shared space. So the app never asks. On first run it mints a random account —
/// an address in a domain we own the naming of, plus a high-entropy password — registers it
/// with the backend, and keeps both in the Keychain/Keystore. Every later launch signs in from
/// that stored pair with no interaction at all.
///
/// The backend contract is unchanged (see backend/src/modules/auth/schemas.ts): the generated
/// address is a real, valid email and the password clears the 8-character minimum by a wide
/// margin. The trade-off is deliberate and documented in docs/ACCESSIBILITY_CHECKLIST.md: the
/// account is bound to the device rather than to a person, so it cannot be recovered onto a new
/// phone. Nothing stored under it is irreplaceable (scan history and allergy profile), and a
/// password a blind user cannot enter unaided is not a usable recovery path either.
///
/// These keys deliberately survive [SecureTokenStorage.clear] — that wipes the *session*, and
/// throwing away the credentials with it would orphan the account and its scan history forever.
class DeviceAccountStore {
  DeviceAccountStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _emailKey = 'nalamai.device.email';
  static const _passwordKey = 'nalamai.device.password';

  Future<DeviceCredentials?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return DeviceCredentials(email: email, password: password);
  }

  Future<bool> exists() async => await read() != null;

  /// Returns this device's credentials, minting and persisting them on first call.
  Future<DeviceCredentials> getOrCreate() async {
    final existing = await read();
    if (existing != null) return existing;

    final credentials = generate();
    await Future.wait([
      _storage.write(key: _emailKey, value: credentials.email),
      _storage.write(key: _passwordKey, value: credentials.password),
    ]);
    return credentials;
  }

  /// Visible for testing — the randomness, not the storage.
  static DeviceCredentials generate({Random? random}) {
    final rng = random ?? Random.secure();
    return DeviceCredentials(
      email: 'nalam.${_randomToken(rng, 12)}@device.nalamai.app',
      password: _randomToken(rng, 32),
    );
  }

  /// URL/base64-safe so the value survives JSON transport and shell-quoting unchanged.
  static String _randomToken(Random rng, int byteLength) {
    final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _emailKey),
      _storage.delete(key: _passwordKey),
    ]);
  }
}
