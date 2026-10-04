# NalamAI — Architecture

NalamAI is a voice-first AI food-label assistant for visually impaired users, supporting Tamil
and English (including mixed Tanglish speech). The system is a monorepo with three parts:

```
/mobile    Flutter application (iOS + Android)
/backend   Node.js/TypeScript API (auth, product data, AI proxying, secrets)
/docs      Architecture, API contracts, DB schema, testing & accessibility docs
```

## Why a backend at all (not a "call OCR/AI straight from the phone" app)

Every third-party AI credential (Google Cloud, Anthropic) lives on the server. The mobile app
never holds a provider API key. This is required for:

- **Secret safety** — a decompiled APK cannot leak Google/Anthropic keys.
- **Central rate limiting / cost control** — one compromised device can't run up unbounded bills.
- **Provider swapping** — the app talks to *our* stable contract (`/api/v1/...`); we can swap
  Google Vision for AWS Textract, or Claude for another model, without shipping a new app build.
- **Auditability** — every OCR/AI call is logged server-side with the user id and product id.

## High-level flow (maps to the 8 layers in the product spec)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. ACCESSIBILITY LAYER (mobile, core/accessibility)                     │
│    VoiceInputService · TtsService · HapticService · SemanticsHelpers    │
└──────────────────────────────┬────────────────────────────────────────-┘
                                │ voice command / gesture
┌──────────────────────────────▼────────────────────────────────────────-┐
│ 2. CAMERA ASSISTANT (mobile, features/scanner)                          │
│    CameraController + FrameQualityAnalyzer (blur/brightness/framing)    │
│    → spoken guidance ("move closer", "hold steady") via TtsService      │
└──────────────────────────────┬────────────────────────────────────────-┘
                                │ captured JPEG (base64) or barcode string
┌──────────────────────────────▼────────────────────────────────────────-┐
│ 3. INFORMATION EXTRACTION (backend, modules/extraction)                 │
│    OcrProvider (Google Vision) · BarcodeLookupProvider (Open Food Facts)│
│    → raw OCR text blocks + regex/heuristic table parser                 │
└──────────────────────────────┬────────────────────────────────────────-┘
                                │ structured ExtractionResult
┌──────────────────────────────▼────────────────────────────────────────-┐
│ 4. FOOD UNDERSTANDING (backend, modules/nutrition)                      │
│    NutritionNormalizer, AllergenTagger, DietClassifier                  │
│    (rule-based; only asserts what the label states or OCR found)        │
└──────────────────────────────┬────────────────────────────────────────-┘
                                │ Product + NutritionFacts + Allergens
┌──────────────────────────────▼────────────────────────────────────────-┐
│ 5. USER PROFILE (backend, modules/profile; mobile secure storage cache) │
│    allergies, diet preferences/restrictions — encrypted at rest         │
└──────────────────────────────┬────────────────────────────────────────-┘
                                │
┌──────────────────────────────▼────────────────────────────────────────-┐
│ 6. SAFETY ANALYSIS (backend, modules/safety)                            │
│    SafetyAnalyzer: allergen-vs-profile diff, nutrition threshold flags  │
│    Every finding is tagged with a provenance source (see below)         │
└──────────────────────────────┬────────────────────────────────────────-┘
                                │
┌──────────────────────────────▼────────────────────────────────────────-┐
│ 7. AI FOOD ASSISTANT (backend, modules/assistant → Anthropic Claude)    │
│    Answers ONLY from the extracted product JSON, cites provenance,      │
│    states uncertainty explicitly, never gives medical verdicts          │
└──────────────────────────────┬────────────────────────────────────────-┘
                                │ AnswerResult { text, language, provenance }
┌──────────────────────────────▼────────────────────────────────────────-┐
│ 8. AUDIO RESPONSE (mobile, core/accessibility/TtsService)               │
│    Tamil/English TTS (on-device flutter_tts, cloud fallback), haptics   │
│    for warnings via HapticService                                       │
└──────────────────────────────────────────────────────────────────────-─┘
```

## Provenance model (drives the "no unsupported medical claims" rule)

Every fact surfaced to the user carries one of these source tags, both in the API payload and in
generated speech:

| Tag | Meaning | Example spoken prefix |
|---|---|---|
| `label_stated` | The text was found verbatim on the OCR'd label | "Label explicitly says..." |
| `ocr_detected` | Derived from OCR text via parsing/regex, not a verbatim quote | "Detected from the label text..." |
| `ai_interpreted` | The LLM inferred it from context (e.g. cuisine guess) | "Our AI interpretation is..." |
| `unverified` | Could not be reliably extracted | "This could not be verified from the label." |

The `SafetyAnalyzer` and `AI Assistant` are contractually forbidden (via prompt + server-side
post-filter, `modules/assistant/safetyFilter.ts`) from emitting: diagnoses, "safe to eat" /
"unsafe to eat" verdicts, or "good food" / "bad food" classifications. See
`docs/SAFETY_RULES.md`.

## Mobile app layering (Flutter, feature-first + clean architecture)

```
mobile/lib/
  core/
    accessibility/   voice input, TTS, haptics, semantics helpers
    network/         Dio client, interceptors, connectivity/offline handling
    storage/         flutter_secure_storage wrappers, local scan cache (sqflite)
    localization/    ARB files (en, ta), language detection helpers
    theme/           accessible theme (large text, high contrast, big targets)
    routing/         go_router config, voice-command → route mapping
    error/           typed Failure/Result types, error mapping
  features/
    onboarding/
    home/                 (Voice-first Home)
    scanner/              (Camera Scanner + Scanning Guidance)
    product_result/       (Product Result, Nutrition Details, Ingredients & Allergens)
    assistant/             (AI Food Assistant chat, voice Q&A)
    comparison/            (Product Comparison)
    profile/               (User Profile, Allergy/Diet Preferences)
    history/               (Scan History)
    settings/               (Settings, Language Settings)
  main.dart
```

Each feature follows `data/` (repositories, DTOs), `domain/` (entities, use cases),
`presentation/` (Riverpod providers + screens/widgets).

## Backend layering (Express + TypeScript, modular monolith)

```
backend/src/
  modules/
    auth/          register/login/refresh/logout, bcrypt + JWT
    profile/        allergy & diet preference CRUD
    extraction/     OCR provider abstraction + Google Vision impl, barcode lookup
    nutrition/      normalizer, allergen tagger, diet classifier
    safety/         allergen-vs-profile diff, nutrition threshold rules
    assistant/      Claude-backed Q&A, prompt builder, safety post-filter
    products/       scan + product + comparison persistence
    tts/            server-proxied Google Cloud TTS (fallback tier only)
  providers/        pluggable interfaces: OcrProvider, AiProvider, TtsProvider,
                    BarcodeLookupProvider — one Google/Anthropic/OpenFoodFacts
                    implementation each, swappable via env var
  middleware/       auth guard, error handler, rate limiter, request logger
  lib/               prisma client, logger (pino), config loader (zod-validated env)
  app.ts / server.ts
prisma/schema.prisma
```

## Key non-functional decisions

- **Auth**: email+password, argon2/bcrypt hashed, short-lived access JWT (15 min) + rotating
  refresh token (30 days) stored in `flutter_secure_storage` on device / hashed in DB on server.
- **Offline**: last N scans + product results are cached locally (sqflite) so Product Result,
  Nutrition Details, Ingredients & Allergens, and History screens work offline; Scanner/Assistant
  require connectivity and surface a clear spoken + visual offline state.
- **Logging**: pino (backend, JSON structured, request-id correlation), no PII in logs (emails
  hashed), `flutter` side uses a thin logger that never logs OCR/photo content.
- **Config**: all secrets via environment variables, validated at boot with `zod`; see
  `backend/.env.example` and `mobile/.env.example`. No secret ever committed.
- **Testing**: backend — Jest + Supertest (unit + integration against a test Postgres schema);
  mobile — `flutter_test` widget/unit tests + `integration_test` for the scan→result flow.
