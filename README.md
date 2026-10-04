# NalamAI

**NalamAI** is a voice-first AI food-label assistant for visually impaired users, supporting
Tamil and English (including mixed Tanglish speech) with automatic language detection.

```
BLIND USER → voice/gesture → camera guidance → OCR/vision/barcode → nutrition & ingredient
extraction → allergen detection → compare with personal profile → ask questions by voice →
Tamil/English audio answer → haptic warnings
```

## No typing, anywhere

The app is built on the assumption that the user cannot see the screen and will never use the
keyboard. That rules out the usual sign-up form, so there isn't one: on first run the app mints
a random account for the device, registers it, and keeps the credentials in the
Keychain/Keystore (`mobile/lib/core/auth/device_account.dart`). Setting up is one spoken word;
every launch after that goes straight to an open microphone. The typed login form still exists,
collapsed, for a sighted helper — voice-first must not mean voice-only.

Beyond that, the same vocabulary works on every screen — "go back", "go home", "help", "where am
I", "repeat that", "stop talking" (`core/accessibility/global_voice_commands.dart`) — screens
re-open the microphone when the user returns to them, failures are spoken and felt rather than
flashed in a snackbar, and the scanner announces when a label is framed and takes the photo
itself, because judging framing is exactly what this user cannot do.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full system design, and:

- [docs/API_CONTRACTS.md](docs/API_CONTRACTS.md) — REST contract between mobile and backend
- [docs/DATABASE.md](docs/DATABASE.md) — schema and design rationale
- [docs/SAFETY_RULES.md](docs/SAFETY_RULES.md) — the non-negotiable safety/provenance rules
  enforced in the AI assistant and rule-based safety analyzer
- [docs/TESTING.md](docs/TESTING.md) — test strategy and how to run everything
- [docs/ACCESSIBILITY_CHECKLIST.md](docs/ACCESSIBILITY_CHECKLIST.md) — manual accessibility pass

## Repository layout

```
/mobile    Flutter app (iOS + Android) — mobile/README.md
/backend   Node.js/TypeScript API — backend/README.md
/docs      Architecture, contracts, schema, testing, accessibility docs
```

## Quick start

```bash
# 1. Backend
cd backend
cp .env.example .env        # fill in secrets, see backend/README.md
npm install
docker compose -f ../docker-compose.yml up -d
npx prisma migrate dev --name init
npm run dev                  # http://localhost:4000

# 2. Mobile (separate terminal)
cd mobile
cp .env.example .env        # point API_BASE_URL at the backend above
flutter pub get
flutter gen-l10n
flutter run
```

Every third-party credential (Google Cloud Vision/Speech/TTS, Anthropic Claude, Open Food Facts)
lives on the backend only — the mobile app never embeds a provider API key. Every provider is
swappable behind an interface (`backend/src/providers/*.provider.ts`) and has a deterministic
mock implementation (`*_PROVIDER=mock`) so the backend and mobile app can both be developed and
tested without any cloud account.

## Safety-first design

This is not a generic chatbot bolted onto OCR. Every fact the app surfaces — nutrition values,
ingredients, allergens — carries a provenance tag (`label_stated` / `ocr_detected` /
`ai_interpreted` / `unverified`) that is spoken aloud, not just shown in fine print. The app
never issues a medical diagnosis, never says a product is "safe to eat", and never reduces a
product to a binary "good"/"bad" verdict — see [docs/SAFETY_RULES.md](docs/SAFETY_RULES.md) for
the full rule set and how it's enforced in three independent layers (prompt constraints, a
deterministic server-side filter, and a rule-based — not LLM-based — allergen/nutrition
analyzer).

## Status

Backend: TypeScript compiles clean (`npm run typecheck`), lints clean (`npm run lint`), and all
27 unit tests pass with zero external dependencies (`npm test -- tests/unit`). Integration tests
are written and require a local Postgres instance (`docker compose up`) not available in this
sandbox — see `backend/README.md`.

Mobile: `flutter analyze` passes with zero issues across the full app, and `flutter test
test/unit` passes (27 tests) — the native-assets tooling bug that previously blocked the runner
on this machine is worked around by the `path_provider_foundation` pin in `mobile/pubspec.yaml`.
