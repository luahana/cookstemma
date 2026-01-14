/**
 * Transform image URLs for web consumption.
 * The backend may return URLs meant for mobile (10.0.2.2 for Android emulator),
 * which need to be converted to localhost for web browsers.
 */
export function getImageUrl(url: string | null | undefined): string | null {
  if (!url) return null;

  // Replace Android emulator localhost with actual localhost
  return url.replace('http://10.0.2.2:9000', 'http://localhost:9000');
}
