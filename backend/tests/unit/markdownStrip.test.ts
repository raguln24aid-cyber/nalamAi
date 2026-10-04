import { stripMarkdown } from '../../src/modules/assistant/markdownStrip';

describe('stripMarkdown', () => {
  it('removes bold markers', () => {
    expect(stripMarkdown('The label **explicitly** says it contains milk.')).toBe(
      'The label explicitly says it contains milk.',
    );
  });

  it('removes italics and underscores', () => {
    expect(stripMarkdown('This is *important* and _also_ this.')).toBe('This is important and also this.');
  });

  it('removes bullet and numbered list markers', () => {
    const input = '- Milk\n- Peanuts\n1. Soy';
    expect(stripMarkdown(input)).toBe('Milk\nPeanuts\nSoy');
  });

  it('removes headings and inline code', () => {
    expect(stripMarkdown('## Sugar\nIt has `12g` of sugar.')).toBe('Sugar\nIt has 12g of sugar.');
  });

  it('leaves plain prose untouched', () => {
    const text = 'The label explicitly says it contains milk and is vegetarian.';
    expect(stripMarkdown(text)).toBe(text);
  });

  it('strips any stray leftover formatting characters', () => {
    expect(stripMarkdown('Contains # peanuts * and milk_')).not.toMatch(/[*_#`]/);
  });
});
