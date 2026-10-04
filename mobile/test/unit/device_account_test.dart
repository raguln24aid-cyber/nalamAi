import 'package:flutter_test/flutter_test.dart';
import 'package:nalamai_mobile/core/auth/device_account.dart';

void main() {
  group('DeviceAccountStore.generate', () {
    test('produces an address the backend will accept as an email', () {
      // backend/src/modules/auth/schemas.ts validates with zod's .email(), so a malformed
      // local part here would fail registration on first run with no way for the user to fix it.
      final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      for (var i = 0; i < 200; i++) {
        expect(emailPattern.hasMatch(DeviceAccountStore.generate().email), isTrue);
      }
    });

    test('produces a password well clear of the 8-character server minimum', () {
      for (var i = 0; i < 50; i++) {
        expect(DeviceAccountStore.generate().password.length, greaterThanOrEqualTo(32));
      }
    });

    test('produces credentials that survive JSON transport unchanged', () {
      for (var i = 0; i < 50; i++) {
        final credentials = DeviceAccountStore.generate();
        expect(credentials.password, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
        expect(credentials.email, isNot(contains('=')));
      }
    });

    test('does not repeat itself', () {
      final emails = List.generate(500, (_) => DeviceAccountStore.generate().email).toSet();
      expect(emails.length, 500);
    });
  });
}
