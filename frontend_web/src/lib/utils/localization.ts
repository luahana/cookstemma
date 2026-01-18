export type TranslationMap = Record<string, string> | null | undefined;

/**
 * Get localized content from a translations map.
 * Returns the translation for the given locale if available,
 * otherwise falls back to the default content.
 *
 * @param translations - Map of locale codes to translated strings
 * @param locale - The target locale (e.g., 'ja', 'ko', 'en')
 * @param fallback - Default content to use when translation is not available
 * @returns The localized string or fallback
 */
export function getLocalizedContent(
  translations: TranslationMap,
  locale: string,
  fallback: string
): string {
  if (translations && locale in translations && translations[locale]) {
    return translations[locale];
  }
  return fallback;
}
