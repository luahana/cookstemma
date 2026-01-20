package com.cookstemma.cookstemma.util;

import java.util.Map;

/**
 * Utility class for locale-aware translation extraction.
 * Provides fallback chain: requestedLocale → en → first available value.
 */
public final class LocaleUtils {

    private LocaleUtils() {
        // Utility class, no instantiation
    }

    /**
     * Extract a single localized value from a translation map.
     * Fallback chain: requestedLocale → "en" → first available → null
     *
     * @param translations Map of locale codes to translated values
     * @param locale       Requested locale code (e.g., "ko-KR", "ja", "en")
     * @return Localized value or null if map is empty
     */
    public static String getLocalizedValue(Map<String, String> translations, String locale) {
        if (translations == null || translations.isEmpty()) {
            return null;
        }

        // Try requested locale first
        if (locale != null && translations.containsKey(locale)) {
            return translations.get(locale);
        }

        // Fallback to English
        if (translations.containsKey("en")) {
            return translations.get("en");
        }

        // Last resort: first available value
        return translations.values().iterator().next();
    }

    /**
     * Extract a single localized value with a default fallback.
     * Fallback chain: requestedLocale → "en" → first available → defaultValue
     *
     * @param translations Map of locale codes to translated values
     * @param locale       Requested locale code
     * @param defaultValue Value to return if no translation found
     * @return Localized value or defaultValue
     */
    public static String getLocalizedValue(Map<String, String> translations, String locale, String defaultValue) {
        String value = getLocalizedValue(translations, locale);
        return value != null ? value : defaultValue;
    }

    /**
     * Normalize locale codes to a consistent format.
     * Converts underscores to hyphens (e.g., "ko_KR" → "ko-KR").
     *
     * @param locale Raw locale string
     * @return Normalized locale string
     */
    public static String normalizeLocale(String locale) {
        if (locale == null) {
            return null;
        }
        return locale.replace("_", "-");
    }

    /**
     * Extract the language code from a full locale (e.g., "ko-KR" → "ko").
     *
     * @param locale Full locale string
     * @return Language code only
     */
    public static String getLanguageCode(String locale) {
        if (locale == null) {
            return null;
        }
        int dashIndex = locale.indexOf('-');
        return dashIndex > 0 ? locale.substring(0, dashIndex) : locale;
    }
}
