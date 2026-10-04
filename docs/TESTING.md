# Testing Strategy

## Backend (`backend/`)

| Layer | Location | Needs | Run |
|---|---|---|---|
| Unit | `tests/unit/**` | nothing — pure functions | `npm test -- tests/unit` |
| Integration | `tests/integration/**` | a real Postgres instance (mock OCR/AI/barcode/TTS providers, no cloud credentials) | see `backend/README.md` |

Unit tests cover the parts of the system with the highest correctness bar and no external
dependencies:
- `labelParser.test.ts` — OCR-text → structured product parsing (nutrition, ingredients,
  allergens, diet flags), including provenance tagging correctness.
- `safetyAnalyzer.test.ts` — the rule-based allergen-vs-profile and nutrition-threshold engine.
  Explicitly asserts it never emits a "safe"/"good food"/"bad food" verdict string.
- `safetyFilter.test.ts` — the deterministic denylist filter that is the last line of defense
  against the LLM producing an unsafe claim.
- `languageDetector.test.ts` — Tamil script + Tanglish keyword detection.

Integration tests exercise the real Express app + Prisma against Postgres with every external
provider swapped to its deterministic mock (`OCR_PROVIDER=mock`, `AI_PROVIDER=mock`, etc., see
`tests/setupEnv.ts`), covering: register/login/refresh-rotation/logout, profile/allergy CRUD,
end-to-end scan → safety-flag generation → AI assistant query, and cross-user access control
(a user cannot read another user's scan).

## Mobile (`mobile/`)

| Layer | Location | Needs |
|---|---|---|
| Unit | `test/unit/**` | nothing |
| Widget | `test/*_test.dart` | nothing (platform plugins faked with `mocktail`) |
| Integration (device/emulator) | `integration_test/` | a running emulator/device + backend |

- `test/unit/frame_quality_analyzer_test.dart` — the camera guidance heuristic (blur/brightness
  detection) tested against synthetic luma buffers (solid dark/bright frames, a checkerboard for
  "sharp"), independent of the real `camera` plugin.
- `test/widget_test.dart` — pumps the real Login screen with a faked `TtsService`, asserting the
  welcome utterance fires, form fields/labels render, and invalid input is rejected client-side.

Run: `flutter test`.

### Known environment limitation

On a machine whose Flutter SDK is installed under a path containing a space (as this
development sandbox's `C:\Users\<name with a space>\...` did), `flutter test` currently fails
during Dart's native-assets build hook for platform-conditional transitive dependencies (e.g.
`path_provider_foundation` → `objective_c`), independent of anything in this codebase — command
construction inside the Dart SDK's hook runner does not quote the SDK path. `flutter analyze`
is unaffected and passed with zero issues. If you hit this, install the Flutter SDK to a
space-free path (e.g. `C:\flutter`) or run tests in CI/CD (Linux/macOS runners, or Windows
runners with a space-free checkout path) instead.

## Manual / device testing checklist (do before shipping)

Run through this on a real Android and iOS device (a simulator cannot exercise the camera or a
real microphone realistically):

1. Camera scanner: label-photo mode — spoken guidance for too dark / too bright / blurry, and a
   successful capture that reaches Product Result.
2. Camera scanner: barcode mode — a known EAN/UPC barcode resolves via Open Food Facts.
3. Voice command from Home ("check this product" / "இந்த பொருளை check பண்ணு") opens the scanner.
4. AI Assistant: ask "What is the sugar content?" in English, then a Tamil question, and confirm
   the response language matches the question language.
5. Add a declared allergen from a real product to your profile, re-scan that product, confirm a
   *critical* safety flag + haptic pattern distinct from a routine tap.
6. Turn on airplane mode: History and a previously-viewed Product Result still open; Scanner and
   AI Assistant show a clear offline message instead of hanging.
7. TalkBack (Android) / VoiceOver (iOS) end-to-end: Home → Scanner → Product Result → Nutrition
   Details, without looking at the screen.
8. Deny camera/mic permission once, confirm the spoken + visual explanation, then grant it from
   Settings and confirm the flow recovers without a restart.

See `docs/ACCESSIBILITY_CHECKLIST.md` for the full accessibility-specific pass.
