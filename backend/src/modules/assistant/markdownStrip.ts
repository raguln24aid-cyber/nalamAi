/**
 * Deterministic cleanup that runs on every AI response regardless of how well the model
 * followed the "no markdown" instruction in prompt.ts — this is a voice interface; a
 * TTS engine reading "asterisk asterisk contains milk asterisk asterisk" aloud is unacceptable,
 * so we never rely on prompt compliance alone (same defense-in-depth principle as
 * safetyFilter.ts).
 */
export function stripMarkdown(text: string): string {
  return (
    text
      // Bold / italics / strikethrough: **x**, __x__, *x*, _x_, ~~x~~ -> x
      .replace(/\*\*(.+?)\*\*/g, '$1')
      .replace(/__(.+?)__/g, '$1')
      .replace(/\*(.+?)\*/g, '$1')
      .replace(/_(.+?)_/g, '$1')
      .replace(/~~(.+?)~~/g, '$1')
      // Inline/fenced code: `x` -> x
      .replace(/```[a-zA-Z]*\n?/g, '')
      .replace(/`([^`]+)`/g, '$1')
      // Headings: "## Title" -> "Title"
      .replace(/^#{1,6}\s+/gm, '')
      // List markers: "- x" / "* x" / "1. x" -> "x"
      .replace(/^[ \t]*[-*+]\s+/gm, '')
      .replace(/^[ \t]*\d+\.\s+/gm, '')
      // Any leftover stray formatting characters
      .replace(/[*_#`]/g, '')
      .replace(/[ \t]{2,}/g, ' ')
      .trim()
  );
}
