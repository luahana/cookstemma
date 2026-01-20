package com.cookstemma.cookstemma.util;

import java.util.Map;

/**
 * Utility class for locale-based content resolution.
 */
public final class LocaleUtils {

    private LocaleUtils() {}

    /**
     * Default locale when none is specified.
     */
    public static final String DEFAULT_LOCALE = "en-US";

    /**
     * Get a localized value from a translations map.
     * Fallback order: requested locale → language-only match → default locale (en-US) → English variants → fallback value → first available → null.
     *
     * @param translations Map of locale code to translated value
     * @param locale       Requested locale (e.g., "ko-KR", "en-US")
     * @param fallback     Fallback value if no translation found
     * @return Localized value or fallback
     */
    public static String getLocalizedValue(Map<String, String> translations, String locale, String fallback) {
        if (translations == null || translations.isEmpty()) {
            return fallback;
        }

        // Normalize locale (e.g., "ko_KR" -> "ko-KR")
        String normalizedLocale = normalizeLocale(locale);

        // 1. Try exact locale match
        if (normalizedLocale != null && translations.containsKey(normalizedLocale)) {
            return translations.get(normalizedLocale);
        }

        // 2. Try language-only match (e.g., "ko" from "ko-KR")
        if (normalizedLocale != null && normalizedLocale.contains("-")) {
            String languageOnly = normalizedLocale.split("-")[0];
            for (Map.Entry<String, String> entry : translations.entrySet()) {
                if (entry.getKey().startsWith(languageOnly + "-") || entry.getKey().equals(languageOnly)) {
                    return entry.getValue();
                }
            }
        }

        // 3. Try default locale (en-US)
        if (translations.containsKey(DEFAULT_LOCALE)) {
            return translations.get(DEFAULT_LOCALE);
        }

        // 4. Try English variants
        for (Map.Entry<String, String> entry : translations.entrySet()) {
            if (entry.getKey().startsWith("en")) {
                return entry.getValue();
            }
        }

        // 5. Return fallback if provided
        if (fallback != null) {
            return fallback;
        }

        // 6. Return first available translation
        return translations.values().stream().findFirst().orElse(null);
    }

    /**
     * Get a localized value from a translations map (without fallback).
     * Fallback chain: requestedLocale → "en" → first available → null
     *
     * @param translations Map of locale codes to translated values
     * @param locale       Requested locale code (e.g., "ko-KR", "ja", "en")
     * @return Localized value or null if map is empty
     */
    public static String getLocalizedValue(Map<String, String> translations, String locale) {
        return getLocalizedValue(translations, locale, null);
    }

    /**
     * Normalize locale format (e.g., "ko_KR" → "ko-KR").
     */
    public static String normalizeLocale(String locale) {
        if (locale == null || locale.isBlank()) {
            return DEFAULT_LOCALE;
        }
        return locale.replace("_", "-");
    }

    /**
     * Convert Spring Locale to locale code string.
     */
    public static String toLocaleCode(java.util.Locale locale) {
        if (locale == null) {
            return DEFAULT_LOCALE;
        }
        String language = locale.getLanguage();
        String country = locale.getCountry();
        if (country == null || country.isBlank()) {
            return language;
        }
        return language + "-" + country;
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
