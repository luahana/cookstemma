/**
 * Get the first visible character (grapheme) from a string.
 * Works correctly with all languages including Korean, Chinese, Japanese, emojis, etc.
 *
 * @param str - The input string
 * @returns The first grapheme, or empty string if input is empty
 */
export function getFirstGrapheme(str: string): string {
  if (!str || typeof str !== 'string') return '';

  // Use spread operator to handle multi-byte Unicode characters
  // This correctly handles Korean, Chinese, Japanese, and most Unicode
  const chars = [...str];
  return chars[0] || '';
}

/**
 * Get the initial character for avatar display.
 * Returns the first grapheme, uppercased only if it's a Latin letter.
 *
 * @param name - The username or display name
 * @returns The initial character for display
 */
export function getAvatarInitial(name: string | null | undefined): string {
  if (!name || typeof name !== 'string') return '?';

  const firstChar = getFirstGrapheme(name.trim());
  if (!firstChar) return '?';

  // Only uppercase Latin letters (a-z, A-Z)
  // Non-Latin scripts (Korean, Chinese, Japanese, etc.) don't have case
  if (/^[a-zA-Z]$/.test(firstChar)) {
    return firstChar.toUpperCase();
  }

  return firstChar;
}
