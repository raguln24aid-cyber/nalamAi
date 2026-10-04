# NalamAI Backend

Node.js/TypeScript API for the NalamAI voice-first food-label assistant. See
[../ARCHITECTURE.md](../ARCHITECTURE.md), [../docs/API_CONTRACTS.md](../docs/API_CONTRACTS.md),
[../docs/DATABASE.md](../docs/DATABASE.md) and [../docs/SAFETY_RULES.md](../docs/SAFETY_RULES.md).

## Prerequisites

- Node.js >= 20
- Docker (for local Postgres) — or any reachable Postgres 14+ instance

## Setup

```bash
cd backend
cp .env.example .env      # fill in real secrets — see below
npm install
docker compose -f ../docker-compose.yml up -d   # starts local Postgres
npx prisma migrate dev --name init               # creates schema in `nalamai` db
npm run dev                                       # http://localhost:4000
```

### Required secrets in `.env`

| Variable | How to get it |
|---|---|
| `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | `openssl rand -base64 48` (generate two different values) |
| `GOOGLE_APPLICATION_CREDENTIALS_JSON_BASE64` | Create a GCP service account with Vision API + Text-to-Speech API enabled, download its JSON key, then `base64 -w0 key.json` (Linux/macOS) or `[Convert]::ToBase64String([IO.File]::ReadAllBytes('key.json'))` (PowerShell) |
| `ANTHROPIC_API_KEY` | https://console.anthropic.com/ → API Keys |

Every provider integration is optional in the sense that setting `OCR_PROVIDER=mock`,
`BARCODE_PROVIDER=mock`, `AI_PROVIDER=mock`, or `TTS_PROVIDER=mock` swaps in a deterministic fake
implementation with no external calls or credentials required — this is what `npm test` uses, and
it's useful for running the mobile app against a backend with zero cloud setup while developing UI.

## Scripts

| Command | Purpose |
|---|---|
| `npm run dev` | Hot-reloading dev server (ts-node-dev) |
| `npm run build` / `npm start` | Compile to `dist/` and run the compiled server (production) |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run lint` | ESLint |
| `npm test` | Jest — unit tests run with no dependencies; integration tests need Postgres (see below) |
| `npm run prisma:migrate` | Create/apply a new local migration |
| `npm run prisma:deploy` | Apply existing migrations (CI/production) |

## Running tests

Unit tests (`tests/unit/**`) are pure functions — parsing, safety rules, language detection — and
run with no external dependencies:

```bash
npm test -- tests/unit
```

Integration tests (`tests/integration/**`) exercise the real Express app + Prisma against Postgres
and use the mock providers (no cloud credentials needed):

```bash
docker compose -f ../docker-compose.yml up -d
DATABASE_URL=postgresql://nalamai:nalamai@localhost:5432/nalamai_test?schema=public \
  npx prisma migrate deploy
npm test
```

## Production

- Build with `npm run build`, run with `npm start` (or containerize — no Dockerfile is bundled by
  default since deployment targets vary; a minimal one is:
  `FROM node:20-alpine`, copy, `npm ci --omit=dev`, `npm run build`, `CMD ["node","dist/server.js"]`).
- Set `NODE_ENV=production`, real secrets, and `RETAIN_SCAN_IMAGES` per your privacy policy.
- Run `npx prisma migrate deploy` as part of your deploy pipeline, before starting new instances.
- The server trusts `X-Request-Id` for log correlation but always overwrites the response header
  with a fresh UUID when the caller didn't supply one — put a reverse proxy (nginx/ALB) in front
  for TLS termination.

## Module map

See [../ARCHITECTURE.md](../ARCHITECTURE.md#backend-layering-express--typescript-modular-monolith).
