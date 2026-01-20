/**
 * Localization utility module.
 *
 * Note: As of the DTO locale filtering update, the backend now returns
 * pre-localized content based on the Accept-Language header. The
 * `getLocalizedContent` function is no longer needed for most use cases
 * since DTOs already contain localized strings.
 */

export type TranslationMap = Record<string, string> | null | undefined;

/**
 * Get localized content from a translations map.
 *
 * @deprecated Backend DTOs now return pre-localized content based on
 * the Accept-Language header. Direct usage of `title`, `description`,
 * etc. fields is preferred.
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
