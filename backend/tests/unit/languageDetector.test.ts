import { detectLanguage, resolveResponseLanguage } from '../../src/modules/assistant/languageDetector';

describe('detectLanguage', () => {
  it('detects Tamil script', () => {
    expect(detectLanguage('இந்த பொருளை சரிபார்க்கவும்')).toBe('ta');
  });

  it('detects English', () => {
    expect(detectLanguage('What is the sugar content?')).toBe('en');
  });

  it('detects Tanglish (romanized Tamil) via keyword markers', () => {
    expect(detectLanguage('intha porulai check pannu')).toBe('ta');
  });
});

describe('resolveResponseLanguage', () => {
  it('honours an explicit language override regardless of question text', () => {
    expect(resolveResponseLanguage('en', 'இந்த பொருளை சரிபார்க்கவும்')).toBe('en');
  });

  it('falls back to detection when auto', () => {
    expect(resolveResponseLanguage('auto', 'What is the sugar content?')).toBe('en');
  });
});
