package com.cookstemma.cookstemma.domain.entity.food;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class FoodMasterTest {

    @Nested
    @DisplayName("getNameByLocale")
    class GetNameByLocaleTests {

        @Test
        @DisplayName("Should return exact match when locale key exists")
        void getNameByLocale_WithExactMatch_ReturnsCorrectName() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of(
                            "ko-KR", "김치",
                            "en-US", "Kimchi",
                            "ja-JP", "キムチ"
                    ))
                    .build();

            // Act & Assert
            assertThat(food.getNameByLocale("ko-KR")).isEqualTo("김치");
            assertThat(food.getNameByLocale("en-US")).isEqualTo("Kimchi");
            assertThat(food.getNameByLocale("ja-JP")).isEqualTo("キムチ");
        }

        @Test
        @DisplayName("Should return translation when short locale code is provided")
        void getNameByLocale_WithShortLocaleCode_ReturnsMatchingTranslation() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of(
                            "ko-KR", "김치",
                            "en-US", "Kimchi",
                            "ja-JP", "キムチ",
                            "zh-CN", "泡菜"
                    ))
                    .build();

            // Act & Assert
            assertThat(food.getNameByLocale("ko")).isEqualTo("김치");
            assertThat(food.getNameByLocale("en")).isEqualTo("Kimchi");
            assertThat(food.getNameByLocale("ja")).isEqualTo("キムチ");
            assertThat(food.getNameByLocale("zh")).isEqualTo("泡菜");
        }

        @Test
        @DisplayName("Should fall back to en-US when locale not found")
        void getNameByLocale_WithUnknownLocale_FallsBackToEnglish() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of(
                            "ko-KR", "김치",
                            "en-US", "Kimchi"
                    ))
                    .build();

            // Act
            String result = food.getNameByLocale("fr-FR");

            // Assert
            assertThat(result).isEqualTo("Kimchi");
        }

        @Test
        @DisplayName("Should fall back to any English variant when en-US not found")
        void getNameByLocale_WithoutEnUS_FallsBackToAnyEnglish() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of(
                            "ko-KR", "김치",
                            "en-GB", "Kimchi"
                    ))
                    .build();

            // Act
            String result = food.getNameByLocale("fr");

            // Assert
            assertThat(result).isEqualTo("Kimchi");
        }

        @Test
        @DisplayName("Should return first available when no fallback matches")
        void getNameByLocale_WithNoFallback_ReturnsFirstAvailable() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of("ko-KR", "김치"))
                    .build();

            // Act
            String result = food.getNameByLocale("fr-FR");

            // Assert
            assertThat(result).isEqualTo("김치");
        }

        @Test
        @DisplayName("Should return Unknown Food when name map is null")
        void getNameByLocale_WithNullName_ReturnsUnknownFood() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(null)
                    .build();

            // Act
            String result = food.getNameByLocale("ko");

            // Assert
            assertThat(result).isEqualTo("Unknown Food");
        }

        @Test
        @DisplayName("Should return Unknown Food when name map is empty")
        void getNameByLocale_WithEmptyName_ReturnsUnknownFood() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(new HashMap<>())
                    .build();

            // Act
            String result = food.getNameByLocale("ko");

            // Assert
            assertThat(result).isEqualTo("Unknown Food");
        }

        @Test
        @DisplayName("Should handle case-insensitive language code matching")
        void getNameByLocale_WithDifferentCase_MatchesCorrectly() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of("ko-KR", "김치"))
                    .build();

            // Act & Assert
            assertThat(food.getNameByLocale("KO")).isEqualTo("김치");
            assertThat(food.getNameByLocale("Ko")).isEqualTo("김치");
        }

        @Test
        @DisplayName("Should prefer exact match over language prefix match")
        void getNameByLocale_WithExactAndPrefixMatch_PrefersExact() {
            // Arrange
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of(
                            "zh-CN", "泡菜",
                            "zh-TW", "泡菜(繁體)"
                    ))
                    .build();

            // Act
            String resultCN = food.getNameByLocale("zh-CN");
            String resultTW = food.getNameByLocale("zh-TW");

            // Assert
            assertThat(resultCN).isEqualTo("泡菜");
            assertThat(resultTW).isEqualTo("泡菜(繁體)");
        }
    }
}
