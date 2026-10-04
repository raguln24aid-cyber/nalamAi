import { logger } from '../../lib/logger';

/**
 * Deterministic last line of defense — see docs/SAFETY_RULES.md. Runs over every AI response
 * before it reaches the client. If a denylisted phrase slips through the prompt constraints,
 * the response is replaced with a hedged fallback and the event is logged for review.
 */
const DENYLIST_PATTERNS: RegExp[] = [
  /\bsafe to eat\b/i,
  /\bsafe for you\b/i,
  /\byou (can|should) (safely )?eat this\b/i,
  /\bthis is (healthy|unhealthy|good for you|bad for you)\b/i,
  /\bdiagnos(e|is|ed|ing)\b/i,
  /\bmedically\b/i,
  /\byou (have|might have|probably have) (an? )?allerg/i,
  /\bI (recommend|advise) you (eat|avoid|take)\b/i,
];

const FALLBACK_MESSAGE: Record<'en' | 'ta', string> = {
  en: "I can share what's on the label, but I can't make a safety judgment call on this. Could you ask about a specific nutrition value, ingredient, or allergen instead?",
  ta: 'லேபிளில் இருக்கும் தகவலை என்னால் பகிர முடியும், ஆனால் பாதுகாப்பு தீர்மானத்தை என்னால் கூற முடியாது. குறிப்பிட்ட ஊட்டச்சத்து மதிப்பு, பொருள் அல்லது ஒவ்வாமை பற்றி கேட்க முடியுமா?',
};

export function applySafetyFilter(response: string, language: 'en' | 'ta'): { text: string; filtered: boolean } {
  const matched = DENYLIST_PATTERNS.find((pattern) => pattern.test(response));
  if (!matched) {
    return { text: response, filtered: false };
  }

  logger.warn({ pattern: matched.source }, 'AI assistant response blocked by safety filter');
  return { text: FALLBACK_MESSAGE[language], filtered: true };
}
