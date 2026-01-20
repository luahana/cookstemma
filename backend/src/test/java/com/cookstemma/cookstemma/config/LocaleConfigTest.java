package com.cookstemma.cookstemma.config;

import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.web.servlet.LocaleResolver;

import java.util.Locale;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for LocaleConfig.
 * Verifies that locale resolution works correctly for all supported languages,
 * including language-only codes (e.g., "zh" → "zh_CN").
 */
class LocaleConfigTest {

    private LocaleResolver localeResolver;

    @BeforeEach
    void setUp() {
        LocaleConfig config = new LocaleConfig();
        localeResolver = config.localeResolver();
    }

    @Nested
    @DisplayName("Language Fallback Resolution")
    class LanguageFallbackResolutionTests {

        @Test
        @DisplayName("Should resolve 'zh' to Simplified Chinese (zh_CN)")
        void shouldResolveZh_ToSimplifiedChinese() {
            // Arrange
            HttpServletRequest request = mockRequestWithAcceptLanguage("zh");

            // Act
            Locale resolved = localeResolver.resolveLocale(request);

            // Assert
            assertThat(resolved.getLanguage()).isEqualTo("zh");
            assertThat(resolved.getCountry()).isEqualTo("CN");
        }

        @Test
        @DisplayName("Should resolve 'zh-CN' to Simplified Chinese (zh_CN)")
        void shouldResolveZhCN_ToSimplifiedChinese() {
            // Arrange
            HttpServletRequest request = mockRequestWithAcceptLanguage("zh-CN");

            // Act
            Locale resolved = localeResolver.resolveLocale(request);

            // Assert
            assertThat(resolved.getLanguage()).isEqualTo("zh");
            assertThat(resolved.getCountry()).isEqualTo("CN");
        }

        @Test
        @DisplayName("Should resolve 'ko' to Korean")
        void shouldResolveKo_ToKorean() {
            // Arrange
            HttpServletRequest request = mockRequestWithAcceptLanguage("ko");

            // Act
            Locale resolved = localeResolver.resolveLocale(request);

            // Assert
            assertThat(resolved.getLanguage()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should resolve 'ja' to Japanese")
        void shouldResolveJa_ToJapanese() {
            // Arrange
            HttpServletRequest request = mockRequestWithAcceptLanguage("ja");

            // Act
            Locale resolved = localeResolver.resolveLocale(request);

            // Assert
            assertThat(resolved.getLanguage()).isEqualTo("ja");
        }

        @Test
        @DisplayName("Should resolve 'en' to English")
        void shouldResolveEn_ToEnglish() {
            // Arrange
            HttpServletRequest request = mockRequestWithAcceptLanguage("en");

            // Act
            Locale resolved = localeResolver.resolveLocale(request);

            // Assert
            assertThat(resolved.getLanguage()).isEqualTo("en");
        }

        @Test
        @DisplayName("Should resolve unsupported locale to default English")
        void shouldResolveUnsupportedLocale_ToDefaultEnglish() {
            // Arrange
            HttpServletRequest request = mockRequestWithAcceptLanguage("xyz");

            // Act
            Locale resolved = localeResolver.resolveLocale(request);

            // Assert
            assertThat(resolved.getLanguage()).isEqualTo("en");
        }

        @Test
        @DisplayName("Should resolve null Accept-Language to default English")
        void shouldResolveNullAcceptLanguage_ToDefaultEnglish() {
            // Arrange
            HttpServletRequest request = mock(HttpServletRequest.class);
            when(request.getHeader("Accept-Language")).thenReturn(null);

            // Act
            Locale resolved = localeResolver.resolveLocale(request);

            // Assert
            assertThat(resolved.getLanguage()).isEqualTo("en");
        }
    }

    @Nested
    @DisplayName("toLocaleCode Conversion")
    class ToLocaleCodeTests {

        @Test
        @DisplayName("Should convert Simplified Chinese to 'zh-CN'")
        void shouldConvertSimplifiedChinese_ToZhCN() {
            // Act
            String code = LocaleConfig.toLocaleCode(Locale.SIMPLIFIED_CHINESE);

            // Assert
            assertThat(code).isEqualTo("zh-CN");
        }

        @Test
        @DisplayName("Should convert Traditional Chinese to 'zh-TW'")
        void shouldConvertTraditionalChinese_ToZhTW() {
            // Act
            String code = LocaleConfig.toLocaleCode(Locale.TRADITIONAL_CHINESE);

            // Assert
            assertThat(code).isEqualTo("zh-TW");
        }

        @Test
        @DisplayName("Should convert Korean to 'ko-KR'")
        void shouldConvertKorean_ToKoKR() {
            // Act
            String code = LocaleConfig.toLocaleCode(Locale.KOREAN);

            // Assert
            assertThat(code).isEqualTo("ko-KR");
        }

        @Test
        @DisplayName("Should convert English to 'en'")
        void shouldConvertEnglish_ToEn() {
            // Act
            String code = LocaleConfig.toLocaleCode(Locale.ENGLISH);

            // Assert
            assertThat(code).isEqualTo("en");
        }

        @Test
        @DisplayName("Should convert Japanese to 'ja'")
        void shouldConvertJapanese_ToJa() {
            // Act
            String code = LocaleConfig.toLocaleCode(Locale.JAPANESE);

            // Assert
            assertThat(code).isEqualTo("ja");
        }

        @Test
        @DisplayName("Should convert null locale to 'en'")
        void shouldConvertNullLocale_ToEn() {
            // Act
            String code = LocaleConfig.toLocaleCode(null);

            // Assert
            assertThat(code).isEqualTo("en");
        }

        @Test
        @DisplayName("Should convert language-only Chinese locale to 'zh-CN'")
        void shouldConvertLanguageOnlyChinese_ToZhCN() {
            // Act
            String code = LocaleConfig.toLocaleCode(new Locale("zh"));

            // Assert
            assertThat(code).isEqualTo("zh-CN");
        }
    }

    @Nested
    @DisplayName("All Supported Locales")
    class AllSupportedLocalesTests {

        @Test
        @DisplayName("Should resolve all 20 supported languages")
        void shouldResolveAll20SupportedLanguages() {
            String[] languages = {
                "en", "ko", "ja", "zh", "de", "fr", "es", "pt", "it", "ar",
                "ru", "id", "vi", "hi", "th", "pl", "tr", "nl", "sv", "fa"
            };

            for (String lang : languages) {
                HttpServletRequest request = mockRequestWithAcceptLanguage(lang);
                Locale resolved = localeResolver.resolveLocale(request);
                assertThat(resolved.getLanguage())
                    .as("Language '%s' should be resolved correctly", lang)
                    .isEqualTo(lang);
            }
        }
    }

    private HttpServletRequest mockRequestWithAcceptLanguage(String acceptLanguage) {
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("Accept-Language")).thenReturn(acceptLanguage);
        // Mock getLocales() to return an enumeration for the AcceptHeaderLocaleResolver
        java.util.Enumeration<Locale> locales = java.util.Collections.enumeration(
            java.util.List.of(Locale.forLanguageTag(acceptLanguage.replace("_", "-")))
        );
        when(request.getLocales()).thenReturn(locales);
        return request;
    }
}
