package com.cookstemma.cookstemma.config;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.LocaleResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver;

import java.util.List;
import java.util.Locale;

/**
 * Configuration for locale resolution from Accept-Language header.
 * Supports 20 languages with English as default.
 * Uses a custom resolver that handles language-only codes (e.g., "zh" → "zh_CN").
 */
@Configuration
public class LocaleConfig implements WebMvcConfigurer {

    /**
     * Supported locales matching the web frontend configuration.
     * Note: Locale.SIMPLIFIED_CHINESE is zh_CN, Locale.KOREAN is ko (no country).
     */
    public static final List<Locale> SUPPORTED_LOCALES = List.of(
            Locale.ENGLISH,                          // en
            Locale.KOREAN,                           // ko
            Locale.JAPANESE,                         // ja
            Locale.SIMPLIFIED_CHINESE,               // zh_CN
            Locale.GERMAN,                           // de
            Locale.FRENCH,                           // fr
            new Locale("es"),                        // es (Spanish)
            new Locale("pt"),                        // pt (Portuguese)
            Locale.ITALIAN,                          // it
            new Locale("ar"),                        // ar (Arabic)
            new Locale("ru"),                        // ru (Russian)
            new Locale("id"),                        // id (Indonesian)
            new Locale("vi"),                        // vi (Vietnamese)
            new Locale("hi"),                        // hi (Hindi)
            new Locale("th"),                        // th (Thai)
            new Locale("pl"),                        // pl (Polish)
            new Locale("tr"),                        // tr (Turkish)
            new Locale("nl"),                        // nl (Dutch)
            new Locale("sv"),                        // sv (Swedish)
            new Locale("fa")                         // fa (Persian)
    );

    @Bean
    public LocaleResolver localeResolver() {
        return new LanguageFallbackLocaleResolver();
    }

    /**
     * Custom locale resolver that extends AcceptHeaderLocaleResolver to support
     * language-only codes. When a request comes with "Accept-Language: zh",
     * it will match to Locale.SIMPLIFIED_CHINESE (zh_CN) via language fallback.
     */
    private static class LanguageFallbackLocaleResolver extends AcceptHeaderLocaleResolver {

        public LanguageFallbackLocaleResolver() {
            setDefaultLocale(Locale.ENGLISH);
            setSupportedLocales(SUPPORTED_LOCALES);
        }

        @Override
        public Locale resolveLocale(HttpServletRequest request) {
            // Get requested locales from Accept-Language header
            java.util.Enumeration<Locale> requestLocales = request.getLocales();
            if (requestLocales == null || !requestLocales.hasMoreElements()) {
                return getDefaultLocale();
            }

            while (requestLocales.hasMoreElements()) {
                Locale requestedLocale = requestLocales.nextElement();

                // 1. Try exact match
                for (Locale supported : SUPPORTED_LOCALES) {
                    if (supported.equals(requestedLocale)) {
                        return supported;
                    }
                }

                // 2. Try language-only match (e.g., "zh" matches "zh_CN")
                String requestedLanguage = requestedLocale.getLanguage();
                for (Locale supported : SUPPORTED_LOCALES) {
                    if (supported.getLanguage().equals(requestedLanguage)) {
                        return supported;
                    }
                }
            }

            // No match found, return default
            return getDefaultLocale();
        }
    }

    /**
     * Convert a Locale to our standard locale code format (e.g., "ko-KR", "ja", "en").
     *
     * @param locale The Locale object
     * @return Standardized locale code
     */
    public static String toLocaleCode(Locale locale) {
        if (locale == null) {
            return "en";
        }

        String language = locale.getLanguage();
        String country = locale.getCountry();

        // For Korean, use "ko-KR" format to match existing data
        if ("ko".equals(language)) {
            return "ko-KR";
        }

        // For Chinese, use "zh-CN" or "zh-TW"
        if ("zh".equals(language)) {
            if ("TW".equals(country) || "HK".equals(country)) {
                return "zh-TW";
            }
            return "zh-CN";
        }

        // For most languages, just use the language code
        return language;
    }
}
