const TAMIL_SCRIPT_RANGE = /[஀-௿]/;

/**
 * Common romanized Tamil ("Tanglish") words/particles that signal Tamil intent even when typed
 * in Latin script, e.g. "இந்த பொருளை check பண்ணு" typed as "intha porulai check pannu".
 * Not exhaustive — a practical heuristic, not an NLU model.
 */
const TANGLISH_MARKERS = [
  'pannu', 'panna', 'irukka', 'irukku', 'enna', 'yenna', 'ithu', 'idhu', 'intha', 'antha',
  'vera', 'venum', 'illa', 'illai', 'sapdu', 'sapdalam', 'sollu', 'solla', 'padikanum',
  'ungal', 'unga', 'nalla', 'romba', 'seekiram', 'poitu', 'irukkuma', 'irundha', 'kondu',
  'sugar irukka', 'evlo', 'ethana', 'porulai', 'porul',
];

/**
 * Heuristic language detector used to auto-route the AI Assistant and TTS response language.
 * Tamil Unicode script is a strong signal; Tanglish (romanized Tamil) falls back to keyword
 * matching. Anything else defaults to English.
 */
export function detectLanguage(text: string): 'en' | 'ta' {
  if (TAMIL_SCRIPT_RANGE.test(text)) return 'ta';

  const lower = text.toLowerCase();
  const markerHits = TANGLISH_MARKERS.filter((marker) => lower.includes(marker)).length;
  if (markerHits >= 1) return 'ta';

  return 'en';
}

export function resolveResponseLanguage(
  requested: 'en' | 'ta' | 'auto' | undefined,
  questionText: string,
): 'en' | 'ta' {
  if (requested === 'en' || requested === 'ta') return requested;
  return detectLanguage(questionText);
}
