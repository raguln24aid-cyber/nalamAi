# Safety & Provenance Rules

These rules are enforced in **three places** so that no single bug can cause an unsafe claim to
reach the user: (1) the Claude system prompt, (2) a deterministic server-side post-filter, (3)
UI copy review. They apply to `modules/safety` (rule-based analysis) and `modules/assistant`
(LLM Q&A) in the backend.

## Hard rules (never violated)

1. **No medical claims or diagnoses.** Never say a food will/won't cause a reaction, is
   "healthy"/"unhealthy" for a medical condition, or give dosage/treatment advice.
2. **No binary "good food" / "bad food" verdicts.** Present facts and flag *why* something may
   need attention; let the user (or their caregiver/doctor) judge.
3. **Never claim a food is "safe to eat."** At most: "No declared allergens matched your profile
   on this label" — which is a statement about the label, not a safety guarantee (labels can be
   wrong, cross-contamination isn't detectable from OCR, etc.). This distinction is spoken aloud,
   not just written in fine print.
4. **Every fact is provenance-tagged** using exactly one of:
   - `label_stated` → spoken/written as "The label explicitly says…"
   - `ocr_detected` → "Detected from the label text…" (parsed/derived, not a verbatim quote)
   - `ai_interpreted` → "Our AI interpretation is…" (LLM inference, lowest confidence)
   - `unverified` → "This could not be verified from the label."
5. **Allergen matches are always explained**, never just flagged. E.g. "This is flagged because
   the label lists 'milk solids' in the ingredients, and milk is in your allergy profile" — not
   just "⚠ Allergen warning."
6. **Undeclared-but-inferred allergens are explicitly distinguished** from declared ones: "The
   label does not carry an explicit allergen declaration, but the ingredient list mentions
   'casein', which is milk-derived and matches your profile" — `declared: false` in the API,
   spoken with the softer, hedged phrasing above.

## Enforcement mechanism

- `backend/src/modules/assistant/prompt.ts` builds a system prompt that (a) includes only the
  structured `Product` JSON (never raw web knowledge about the brand) and (b) restates rules 1–4
  as hard constraints with examples.
- `backend/src/modules/assistant/safetyFilter.ts` runs a deterministic regex/keyword scan over
  every model response before it is returned to the client. Matches against a denylist (e.g.
  "safe to eat", "you can eat this", "this is healthy", "diagnos", "medically") cause the
  response to be replaced with a hedged fallback and the event to be logged for review — the
  filtered response is never silently sent.
- `modules/safety/SafetyAnalyzer.ts` is rule-based (no LLM) for the allergen-vs-profile diff and
  nutrition-threshold flags, so the primary safety signal never depends on model behavior at all;
  the LLM only explains/answers questions about data the rule-based analyzer already produced.

## Nutrition threshold flags (informational, not medical)

Thresholds are based on published general-population reference values (e.g. FSSAI/Codex
"high in" thresholds per 100g: sugar ≥ 22.5g, saturated fat ≥ 5g, sodium ≥ 600mg) and are always
phrased as "This is relatively high in X compared to general reference levels" with source
`ai_interpreted` or `ocr_detected` as appropriate — never "this is bad for you" or tied to any
specific medical condition.
