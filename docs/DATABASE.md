# Database Schema

Source of truth: [`backend/prisma/schema.prisma`](../backend/prisma/schema.prisma). This document
explains the *why* behind the shape; regenerate an ER diagram with
`npx prisma generate && npx prisma-erd-generator` if needed.

## Entity overview

| Table | Purpose |
|---|---|
| `users` | Auth identity + preferred language (`en` / `ta` / `auto`). |
| `refresh_tokens` | Hashed rotating refresh tokens (never store raw tokens). |
| `user_profiles` | Single dietary preference (vegetarian/vegan/eggetarian/non-vegetarian/none). |
| `allergies` | 0..N user-declared allergens with severity. |
| `dietary_restrictions` | 0..N free-form restrictions (e.g. "low sodium"). |
| `products` | A physical product, identified by barcode when known. Products are shared/deduplicated across users when the barcode matches. |
| `scans` | One scanning session by a user; links to a `product` once extraction completes. Holds raw OCR text + status for debugging/audit. |
| `nutrition_facts` | 1:1 with `products`. All nullable — absence means "not found on label", never zero. |
| `ingredients` | Ordered ingredient list per product. |
| `allergens` | Per-product allergen list. `declared=true` means the label explicitly stated it (e.g. "Contains: Milk"); `declared=false` means it was inferred by matching an ingredient name against a known allergen dictionary — this distinction is surfaced to the user per the provenance rules in `SAFETY_RULES.md`. |
| `diet_flags` | Vegetarian/vegan/non-veg/gluten flags, each with its own provenance — only ever set when the label supports it. |
| `safety_flags` | **Snapshot** of the allergen/nutrition comparison against the user's profile *at scan time*. Snapshotted (not recomputed on read) so Scan History stays accurate even after the user edits their profile. |
| `chat_messages` | AI Food Assistant conversation log, optionally scoped to a `scan` for "read the ingredients" / "compare with the previous product" style follow-ups. |

## Design decisions

- **No raw photos stored.** Camera frames are sent to the backend over TLS for OCR/vision
  processing and are not persisted — only the derived OCR text and structured product data are
  kept. This limits PII exposure and storage cost. (Configurable via
  `RETAIN_SCAN_IMAGES` env flag for deployments that want an audit trail; default `false`.)
  See `backend/src/modules/extraction`.
- **Products are shared across users** when barcodes match, so a second user scanning the same
  packaged product reuses existing OCR/nutrition work instead of re-extracting it. OCR-only
  products (no barcode, e.g. loose/fresh items with printed labels) are never shared automatically
  since two different photos are unlikely to be the same physical batch.
- **Provenance is a first-class column**, not a UI-only label, on every extracted fact
  (`nutrition_facts`, `ingredients`, `allergens`, `diet_flags`) and on every `safety_flags` row.
  This is what lets the AI Assistant and TTS layer say "label explicitly says" vs "AI
  interpretation" instead of asserting everything with equal confidence.
- **Refresh tokens are hashed** (SHA-256) before storage; only the hash is persisted, matching
  standard rotating-refresh-token practice.

## Migrations

Run with Prisma: `npx prisma migrate dev --name init` (development),
`npx prisma migrate deploy` (production/CI). See `backend/README.md`.
