# NalamAI Mobile

Flutter app for the NalamAI voice-first food-label assistant. See
[../ARCHITECTURE.md](../ARCHITECTURE.md) for the full system design and
[../docs/API_CONTRACTS.md](../docs/API_CONTRACTS.md) for the backend contract this app talks to.

## Prerequisites

- Flutter 3.32+ / Dart 3.8+ (developed against Flutter 3.38.7)
- A running instance of `../backend` (see `backend/README.md`) — the app never talks to any
  third-party AI/OCR/TTS provider directly, only to this backend.
- Android Studio / Xcode for platform builds; a physical device is strongly recommended for
  testing camera, microphone, and TalkBack/VoiceOver, which behave inconsistently on emulators.

## Setup

```bash
cd mobile
cp .env.example .env     # edit API_BASE_URL to point at your backend (see comments in the file)
flutter pub get
flutter gen-l10n          # regenerate localization classes after editing lib/l10n/*.arb
flutter run
```

`API_BASE_URL` in `.env` must be reachable from the device/emulator you're running on:
- Android emulator → host machine's backend: `http://10.0.2.2:4000/api/v1`
- iOS simulator → host machine's backend: `http://localhost:4000/api/v1`
- Physical device → your machine's LAN IP, e.g. `http://192.168.1.20:4000/api/v1`, and the
  backend's `CORS_ALLOWED_ORIGINS` / firewall must allow it.

## Permissions

Camera, microphone, and (on Android) speech-recognition-service package visibility are declared
in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`. The app requests
camera/microphone permission at the point of use (Scanner screen, mic buttons) via
`permission_handler`, and always shows a spoken + visual explanation on denial — never a silent
failure (see `docs/ACCESSIBILITY_CHECKLIST.md`).

## Architecture

Feature-first + a pragmatic clean-architecture split: `core/` holds cross-cutting concerns
(accessibility services, networking, storage, theming, routing), `features/<name>/` holds
`application/` (Riverpod controllers/providers) and `presentation/` (screens/widgets) per screen
group, and `shared/widgets/` holds components reused across features (safety flag cards,
provenance labels, the offline banner, the big mic button). See
[../ARCHITECTURE.md](../ARCHITECTURE.md#mobile-app-layering-flutter-feature-first--clean-architecture).

Every third-party AI/OCR/TTS/barcode-database credential lives on the backend — this app never
embeds a provider API key. On-device `speech_to_text`/`flutter_tts` are used first for
responsiveness and offline-friendliness; the backend-proxied Google Cloud Speech/TTS is only a
fallback for languages/voices the device itself can't handle well (primarily some Android
devices' Tamil TTS quality) — see `core/accessibility/tts_service.dart` and
`core/accessibility/voice_input_service.dart`.

## Testing

```bash
flutter analyze   # static analysis — 0 issues as of this commit
flutter test       # unit + widget tests, see ../docs/TESTING.md
```

See `../docs/TESTING.md` for what's covered, what needs a real device, and a known Windows
native-assets tooling limitation on paths containing spaces.

## Accessibility

This is the core requirement, not an add-on — see `../docs/ACCESSIBILITY_CHECKLIST.md` for the
full manual test pass. Key implementation points:
- `AppTheme` enforces a 56dp minimum touch target and scaled, high-contrast text.
- Every screen's primary action is reachable by voice command (`core/accessibility/
  voice_command_parser.dart`) as well as touch — never voice-only or touch-only.
- `HapticService` gives critical/warning/info safety flags physically distinct vibration
  patterns, not just a color change.
- `Semantics` widgets and live regions are used throughout so TalkBack/VoiceOver announce
  dynamic content (scan results, guidance changes) without manual re-focus.

## Production build

```bash
flutter build apk --release   # Android
flutter build ipa --release   # iOS (requires macOS + signing setup)
```

Set `ENVIRONMENT=production` and a production `API_BASE_URL` in `.env` before building. No
secrets belong in this app's `.env` — see the comment at the top of `.env.example`.
