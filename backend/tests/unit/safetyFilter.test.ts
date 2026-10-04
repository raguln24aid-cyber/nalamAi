import { applySafetyFilter } from '../../src/modules/assistant/safetyFilter';

describe('applySafetyFilter', () => {
  it('passes through a properly hedged response unchanged', () => {
    const text = 'The label explicitly says this contains milk, which matches your allergy profile.';
    const result = applySafetyFilter(text, 'en');
    expect(result.filtered).toBe(false);
    expect(result.text).toBe(text);
  });

  it('blocks a response that claims the food is "safe to eat"', () => {
    const result = applySafetyFilter('Yes, this is safe to eat for you.', 'en');
    expect(result.filtered).toBe(true);
    expect(result.text).not.toMatch(/safe to eat/i);
  });

  it('blocks a binary healthy/unhealthy verdict', () => {
    const result = applySafetyFilter('This is unhealthy so avoid it.', 'en');
    expect(result.filtered).toBe(true);
  });

  it('blocks a medical diagnosis style response', () => {
    const result = applySafetyFilter('You might have an allergy to this ingredient.', 'en');
    expect(result.filtered).toBe(true);
  });

  it('returns the Tamil fallback message when filtering a Tamil-language response', () => {
    const result = applySafetyFilter('This is safe to eat.', 'ta');
    expect(result.filtered).toBe(true);
    expect(result.text).toMatch(/[஀-௿]/);
  });
});
