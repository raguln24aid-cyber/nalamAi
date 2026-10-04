# API Contracts — `/api/v1`

Base URL: `${API_BASE_URL}/api/v1` (see `backend/.env.example` / `mobile/.env.example`).
All request/response bodies are JSON. All authenticated routes require
`Authorization: Bearer <accessToken>`. Errors always use the shape:

```jsonc
{
  "error": {
    "code": "VALIDATION_ERROR",      // machine-readable, stable
    "message": "email is required",  // human-readable, English (client localizes)
    "details": { "field": "email" }  // optional
  }
}
```

Standard error codes: `VALIDATION_ERROR` (400), `UNAUTHORIZED` (401), `FORBIDDEN` (403),
`NOT_FOUND` (404), `CONFLICT` (409), `RATE_LIMITED` (429), `EXTRACTION_FAILED` (422),
`PROVIDER_UNAVAILABLE` (502), `INTERNAL_ERROR` (500).

## Auth — `modules/auth`

### `POST /auth/register`
Body: `{ "email": string, "password": string (min 8), "preferredLanguage"?: "en"|"ta"|"auto" }`
201: `{ "user": UserDto, "accessToken": string, "refreshToken": string }`
409 `CONFLICT` if email exists.

### `POST /auth/login`
Body: `{ "email": string, "password": string }`
200: `{ "user": UserDto, "accessToken": string, "refreshToken": string }`
401 on bad credentials (deliberately same error for "no such user" vs "wrong password").

### `POST /auth/refresh`
Body: `{ "refreshToken": string }`
200: `{ "accessToken": string, "refreshToken": string }` (rotated — old one is revoked).

### `POST /auth/logout` *(auth required)*
Body: `{ "refreshToken": string }` → revokes it. 204.

`UserDto = { id, email, preferredLanguage, createdAt }`

## Profile — `modules/profile` *(all auth required)*

### `GET /profile`
200: `{ "dietaryPreference": DietaryPreference, "notes": string|null, "allergies": Allergy[], "restrictions": DietaryRestriction[] }`

### `PUT /profile`
Body: `{ "dietaryPreference"?: DietaryPreference, "notes"?: string }` → 200 updated profile.

### `POST /profile/allergies`
Body: `{ "allergen": string, "severity": "mild"|"moderate"|"severe" }` → 201 `Allergy`.

### `DELETE /profile/allergies/:id` → 204

### `POST /profile/restrictions`
Body: `{ "restriction": string }` → 201 `DietaryRestriction`.

### `DELETE /profile/restrictions/:id` → 204

## Scanning / extraction — `modules/extraction` + `modules/products` *(auth required)*

### `POST /scans`
Starts a scan from a captured frame and/or barcode. At least one of `imageBase64`, `barcode`
must be present.

Body:
```jsonc
{
  "imageBase64"?: string,       // JPEG, base64, no data: prefix; max ~6MB decoded
  "barcode"?: string,
  "languageHint"?: "en" | "ta" | "auto"
}
```
202 (processing is synchronous in v1 but modeled as async-capable for future queueing):
```jsonc
{
  "scanId": "uuid",
  "status": "completed" | "failed",
  "product": ProductDto | null,
  "safetyFlags": SafetyFlagDto[],
  "languageDetected": "en" | "ta",
  "errorMessage": string | null
}
```
422 `EXTRACTION_FAILED` with a `details.reason` in
`{ "no_text_detected" | "image_too_blurry" | "barcode_not_found" | "provider_error" }` — the
mobile Camera Assistant maps these directly to spoken guidance.

`ProductDto`:
```jsonc
{
  "id": "uuid",
  "barcode": string | null,
  "name": string | null,
  "brand": string | null,
  "nutritionFacts": {
    "servingSize": string | null,
    "calories": number | null, "sugarG": number | null, "proteinG": number | null,
    "fatG": number | null, "saturatedFatG": number | null, "sodiumMg": number | null,
    "fiberG": number | null,
    "provenance": ProvenanceSource
  } | null,
  "ingredients": [{ "name": string, "position": number, "provenance": ProvenanceSource }],
  "allergens": [{ "name": string, "declared": boolean, "provenance": ProvenanceSource }],
  "dietFlags": [{ "type": DietFlagType, "provenance": ProvenanceSource }]
}
```
`ProvenanceSource = "label_stated" | "ocr_detected" | "ai_interpreted" | "unverified"`

### `GET /scans` — query `?limit=&cursor=` → `{ "items": ScanSummaryDto[], "nextCursor": string|null }`
### `GET /scans/:id` → full `ScanDto` (same shape as the POST response)
### `GET /scans/compare?a=:scanId&b=:scanId` →
```jsonc
{ "a": ScanDto, "b": ScanDto, "differences": [
  { "field": "sugarG", "a": 12, "b": 30, "note": "Product B has more sugar per serving." }
]}
```

## AI Food Assistant — `modules/assistant` *(auth required)*

### `POST /assistant/query`
Body: `{ "scanId": string, "question": string, "language"?: "en"|"ta"|"auto", "compareScanId"?: string }`
200:
```jsonc
{
  "answer": string,
  "language": "en" | "ta",
  "provenanceUsed": ProvenanceSource[],
  "uncertain": boolean
}
```
The handler loads the `Product` for `scanId` (and `compareScanId` if given), builds a
constrained prompt (see `SAFETY_RULES.md`), calls the `AiProvider`, runs the response through
`safetyFilter.ts`, and persists both messages to `chat_messages`.

### `GET /assistant/history?scanId=` → `ChatMessageDto[]`

## Text-to-speech fallback — `modules/tts` *(auth required, rate-limited)*

Only used when on-device TTS quality is insufficient (primarily some Tamil voices on older
Android versions). The mobile client always tries on-device `flutter_tts` first.

### `POST /tts/synthesize`
Body: `{ "text": string, "language": "en"|"ta" }`
200: `audio/mpeg` binary stream (not JSON) — mobile plays it via `just_audio`.

## Health

### `GET /health` → `{ "status": "ok", "version": string }` (no auth; used by mobile offline banner + infra probes)
