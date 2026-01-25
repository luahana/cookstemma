package com.cookstemma.cookstemma.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class LocaleUtilsTest {

    @Nested
    @DisplayName("getLocalizedValue")
    class GetLocalizedValueTests {

        @Test
        @DisplayName("Should return exact match when locale key exists")
        void getLocalizedValue_WithExactMatch_ReturnsCorrectValue() {
            // Arrange
            Map<String, String> translations = Map.of(
                    "ko-KR", "김치",
                    "en-US", "Kimchi",
                    "ja-JP", "キムチ"
            );

            // Act & Assert
            assertThat(LocaleUtils.getLocalizedValue(translations, "ko-KR")).isEqualTo("김치");
            assertThat(LocaleUtils.getLocalizedValue(translations, "en-US")).isEqualTo("Kimchi");
            assertThat(LocaleUtils.getLocalizedValue(translations, "ja-JP")).isEqualTo("キムチ");
        }

        @Test
        @DisplayName("Should match short locale code to full locale key")
        void getLocalizedValue_WithShortCode_MatchesFullLocaleKey() {
            // Arrange - Keys have country codes (ko-KR, en-US, etc.)
            Map<String, String> translations = Map.of(
                    "ko-KR", "김치",
                    "en-US", "Kimchi",
                    "ja-JP", "キムチ",
                    "zh-CN", "泡菜"
            );

            // Act & Assert - Short codes should match full locale keys
            assertThat(LocaleUtils.getLocalizedValue(translations, "ko")).isEqualTo("김치");
            assertThat(LocaleUtils.getLocalizedValue(translations, "en")).isEqualTo("Kimchi");
            assertThat(LocaleUtils.getLocalizedValue(translations, "ja")).isEqualTo("キムチ");
            assertThat(LocaleUtils.getLocalizedValue(translations, "zh")).isEqualTo("泡菜");
        }

        @Test
        @DisplayName("Should match full locale code to short key")
        void getLocalizedValue_WithFullCode_MatchesShortKey() {
            // Arrange - Keys are short codes (ko, en, etc.)
            Map<String, String> translations = Map.of(
                    "ko", "김치",
                    "en", "Kimchi",
                    "ja", "キムチ"
            );

            // Act & Assert - Full locale codes should match short keys
            assertThat(LocaleUtils.getLocalizedValue(translations, "ko-KR")).isEqualTo("김치");
            assertThat(LocaleUtils.getLocalizedValue(translations, "en-US")).isEqualTo("Kimchi");
            assertThat(LocaleUtils.getLocalizedValue(translations, "ja-JP")).isEqualTo("キムチ");
        }

        @Test
        @DisplayName("Should be case insensitive for language code matching")
        void getLocalizedValue_CaseInsensitive_MatchesCorrectly() {
            // Arrange
            Map<String, String> translations = Map.of("ko-KR", "김치");

            // Act & Assert
            assertThat(LocaleUtils.getLocalizedValue(translations, "KO")).isEqualTo("김치");
            assertThat(LocaleUtils.getLocalizedValue(translations, "Ko")).isEqualTo("김치");
            assertThat(LocaleUtils.getLocalizedValue(translations, "KO-kr")).isEqualTo("김치");
        }

        @Test
        @DisplayName("Should fall back to en-US when locale not found")
        void getLocalizedValue_WithUnknownLocale_FallsBackToEnUS() {
            // Arrange
            Map<String, String> translations = Map.of(
                    "ko-KR", "김치",
                    "en-US", "Kimchi"
            );

            // Act
            String result = LocaleUtils.getLocalizedValue(translations, "fr-FR");

            // Assert
            assertThat(result).isEqualTo("Kimchi");
        }

        @Test
        @DisplayName("Should fall back to any English variant when en-US not found")
        void getLocalizedValue_WithoutEnUS_FallsBackToAnyEnglish() {
            // Arrange
            Map<String, String> translations = Map.of(
                    "ko-KR", "김치",
                    "en-GB", "Kimchi"
            );

            // Act
            String result = LocaleUtils.getLocalizedValue(translations, "fr");

            // Assert
            assertThat(result).isEqualTo("Kimchi");
        }

        @Test
        @DisplayName("Should return fallback when translations is null")
        void getLocalizedValue_WithNullTranslations_ReturnsFallback() {
            // Act
            String result = LocaleUtils.getLocalizedValue(null, "ko", "Fallback");

            // Assert
            assertThat(result).isEqualTo("Fallback");
        }

        @Test
        @DisplayName("Should return fallback when translations is empty")
        void getLocalizedValue_WithEmptyTranslations_ReturnsFallback() {
            // Act
            String result = LocaleUtils.getLocalizedValue(new HashMap<>(), "ko", "Fallback");

            // Assert
            assertThat(result).isEqualTo("Fallback");
        }

        @Test
        @DisplayName("Should return first available when no match and no fallback")
        void getLocalizedValue_WithNoMatchAndNoFallback_ReturnsFirstAvailable() {
            // Arrange
            Map<String, String> translations = Map.of("ko-KR", "김치");

            // Act
            String result = LocaleUtils.getLocalizedValue(translations, "fr-FR", null);

            // Assert - Should try en-US first, then any en, then first available
            assertThat(result).isEqualTo("김치");
        }

        @Test
        @DisplayName("Should prefer BCP47 key over short key when both exist with different values")
        void getLocalizedValue_WithBothBCP47AndShortKey_PrefersBCP47() {
            // Arrange - Both "ko-KR" and "ko" exist with different values
            // This can happen when translation adds short key with stripped adjectives
            Map<String, String> translations = new HashMap<>();
            translations.put("ko-KR", "연어 구이");  // Original: grilled salmon
            translations.put("ko", "연어");          // Stripped: salmon (shorter name)
            translations.put("en-US", "Grilled Salmon");

            // Act - Request with short code "ko"
            String resultWithShortCode = LocaleUtils.getLocalizedValue(translations, "ko");

            // Assert - Should prefer BCP47 "ko-KR" over short "ko"
            assertThat(resultWithShortCode).isEqualTo("연어 구이");
        }

        @Test
        @DisplayName("Should prefer BCP47 key when requesting with BCP47 locale and short key also exists")
        void getLocalizedValue_WithBCP47Request_PrefersBCP47Key() {
            // Arrange
            Map<String, String> translations = new HashMap<>();
            translations.put("ko-KR", "연어 구이");
            translations.put("ko", "연어");

            // Act - Request with BCP47 "ko-KR" should exact match first
            String result = LocaleUtils.getLocalizedValue(translations, "ko-KR");

            // Assert
            assertThat(result).isEqualTo("연어 구이");
        }

        @Test
        @DisplayName("Should fall back to short key when only short key exists")
        void getLocalizedValue_WithOnlyShortKey_FallsBackToShortKey() {
            // Arrange - Only short key exists (no BCP47)
            Map<String, String> translations = Map.of(
                    "ko", "김치",
                    "en-US", "Kimchi"
            );

            // Act
            String result = LocaleUtils.getLocalizedValue(translations, "ko-KR");

            // Assert - Should use short key as fallback
            assertThat(result).isEqualTo("김치");
        }

        @Test
        @DisplayName("Should prefer BCP47 key consistently regardless of map iteration order")
        void getLocalizedValue_MultipleCallsWithMixedKeys_AlwaysPrefersBCP47() {
            // Arrange - Test multiple times to catch iteration order issues
            for (int i = 0; i < 10; i++) {
                Map<String, String> translations = new HashMap<>();
                translations.put("ko-KR", "연어 구이");
                translations.put("ko", "연어");

                // Act
                String result = LocaleUtils.getLocalizedValue(translations, "ko");

                // Assert - Should always return BCP47 value
                assertThat(result)
                        .as("Iteration %d: Should always prefer BCP47 key", i)
                        .isEqualTo("연어 구이");
            }
        }
    }

    @Nested
    @DisplayName("normalizeLocale")
    class NormalizeLocaleTests {

        @Test
        @DisplayName("Should replace underscore with dash")
        void normalizeLocale_WithUnderscore_ReplaceWithDash() {
            assertThat(LocaleUtils.normalizeLocale("ko_KR")).isEqualTo("ko-KR");
            assertThat(LocaleUtils.normalizeLocale("en_US")).isEqualTo("en-US");
        }

        @Test
        @DisplayName("Should return default locale for null or blank")
        void normalizeLocale_WithNullOrBlank_ReturnsDefault() {
            assertThat(LocaleUtils.normalizeLocale(null)).isEqualTo("en-US");
            assertThat(LocaleUtils.normalizeLocale("")).isEqualTo("en-US");
            assertThat(LocaleUtils.normalizeLocale("  ")).isEqualTo("en-US");
        }
    }

    @Nested
    @DisplayName("getLanguageCode")
    class GetLanguageCodeTests {

        @Test
        @DisplayName("Should extract language code from full locale")
        void getLanguageCode_WithFullLocale_ExtractsLanguage() {
            assertThat(LocaleUtils.getLanguageCode("ko-KR")).isEqualTo("ko");
            assertThat(LocaleUtils.getLanguageCode("en-US")).isEqualTo("en");
            assertThat(LocaleUtils.getLanguageCode("zh-CN")).isEqualTo("zh");
        }

        @Test
        @DisplayName("Should return as-is when no country code")
        void getLanguageCode_WithShortCode_ReturnsAsIs() {
            assertThat(LocaleUtils.getLanguageCode("ko")).isEqualTo("ko");
            assertThat(LocaleUtils.getLanguageCode("en")).isEqualTo("en");
        }
    }

    @Nested
    @DisplayName("toBcp47")
    class ToBcp47Tests {

        @Test
        @DisplayName("Should return as-is when already BCP47 format")
        void toBcp47_WithBCP47_ReturnsAsIs() {
            assertThat(LocaleUtils.toBcp47("ko-KR")).isEqualTo("ko-KR");
            assertThat(LocaleUtils.toBcp47("en-US")).isEqualTo("en-US");
            assertThat(LocaleUtils.toBcp47("ja-JP")).isEqualTo("ja-JP");
            assertThat(LocaleUtils.toBcp47("zh-CN")).isEqualTo("zh-CN");
        }

        @Test
        @DisplayName("Should convert short code to BCP47 for known locales")
        void toBcp47_WithShortCode_ConvertsToBCP47() {
            assertThat(LocaleUtils.toBcp47("ko")).isEqualTo("ko-KR");
            assertThat(LocaleUtils.toBcp47("en")).isEqualTo("en-US");
            assertThat(LocaleUtils.toBcp47("ja")).isEqualTo("ja-JP");
            assertThat(LocaleUtils.toBcp47("zh")).isEqualTo("zh-CN");
            assertThat(LocaleUtils.toBcp47("ar")).isEqualTo("ar-SA");
            assertThat(LocaleUtils.toBcp47("pt")).isEqualTo("pt-BR");
            assertThat(LocaleUtils.toBcp47("sv")).isEqualTo("sv-SE");
            assertThat(LocaleUtils.toBcp47("fa")).isEqualTo("fa-IR");
        }

        @Test
        @DisplayName("Should convert all 20 supported locales")
        void toBcp47_AllSupportedLocales_ConvertCorrectly() {
            // All 20 supported languages
            assertThat(LocaleUtils.toBcp47("en")).isEqualTo("en-US");
            assertThat(LocaleUtils.toBcp47("zh")).isEqualTo("zh-CN");
            assertThat(LocaleUtils.toBcp47("es")).isEqualTo("es-ES");
            assertThat(LocaleUtils.toBcp47("ja")).isEqualTo("ja-JP");
            assertThat(LocaleUtils.toBcp47("de")).isEqualTo("de-DE");
            assertThat(LocaleUtils.toBcp47("fr")).isEqualTo("fr-FR");
            assertThat(LocaleUtils.toBcp47("pt")).isEqualTo("pt-BR");
            assertThat(LocaleUtils.toBcp47("ko")).isEqualTo("ko-KR");
            assertThat(LocaleUtils.toBcp47("it")).isEqualTo("it-IT");
            assertThat(LocaleUtils.toBcp47("ar")).isEqualTo("ar-SA");
            assertThat(LocaleUtils.toBcp47("ru")).isEqualTo("ru-RU");
            assertThat(LocaleUtils.toBcp47("id")).isEqualTo("id-ID");
            assertThat(LocaleUtils.toBcp47("vi")).isEqualTo("vi-VN");
            assertThat(LocaleUtils.toBcp47("hi")).isEqualTo("hi-IN");
            assertThat(LocaleUtils.toBcp47("th")).isEqualTo("th-TH");
            assertThat(LocaleUtils.toBcp47("pl")).isEqualTo("pl-PL");
            assertThat(LocaleUtils.toBcp47("tr")).isEqualTo("tr-TR");
            assertThat(LocaleUtils.toBcp47("nl")).isEqualTo("nl-NL");
            assertThat(LocaleUtils.toBcp47("sv")).isEqualTo("sv-SE");
            assertThat(LocaleUtils.toBcp47("fa")).isEqualTo("fa-IR");
        }

        @Test
        @DisplayName("Should normalize underscore to dash before conversion")
        void toBcp47_WithUnderscore_NormalizesAndConverts() {
            assertThat(LocaleUtils.toBcp47("ko_KR")).isEqualTo("ko-KR");
            assertThat(LocaleUtils.toBcp47("en_US")).isEqualTo("en-US");
        }

        @Test
        @DisplayName("Should return default locale for null or blank input")
        void toBcp47_WithNullOrBlank_ReturnsDefault() {
            assertThat(LocaleUtils.toBcp47(null)).isEqualTo("en-US");
            assertThat(LocaleUtils.toBcp47("")).isEqualTo("en-US");
            assertThat(LocaleUtils.toBcp47("  ")).isEqualTo("en-US");
        }

        @Test
        @DisplayName("Should generate BCP47 for unknown short codes")
        void toBcp47_WithUnknownShortCode_GeneratesDefault() {
            // Unknown short codes should generate xx-XX format
            assertThat(LocaleUtils.toBcp47("xx")).isEqualTo("xx-XX");
            assertThat(LocaleUtils.toBcp47("abc")).isEqualTo("abc-ABC");
        }

        @Test
        @DisplayName("Should be case insensitive for short codes")
        void toBcp47_WithUppercaseShortCode_ConvertCorrectly() {
            assertThat(LocaleUtils.toBcp47("KO")).isEqualTo("ko-KR");
            assertThat(LocaleUtils.toBcp47("EN")).isEqualTo("en-US");
            assertThat(LocaleUtils.toBcp47("Ko")).isEqualTo("ko-KR");
        }
    }
}
