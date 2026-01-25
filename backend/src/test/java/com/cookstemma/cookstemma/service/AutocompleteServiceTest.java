package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.autocomplete.AutocompleteItem;
import com.cookstemma.cookstemma.domain.enums.AutocompleteType;
import com.cookstemma.cookstemma.dto.autocomplete.AutocompleteDto;
import com.cookstemma.cookstemma.repository.autocomplete.AutocompleteItemRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("AutocompleteService Tests")
class AutocompleteServiceTest extends BaseIntegrationTest {

    @Autowired
    private AutocompleteService autocompleteService;

    @Autowired
    private AutocompleteItemRepository autocompleteItemRepository;

    @BeforeEach
    void setUp() {
        // Clear existing data for isolation
        autocompleteItemRepository.deleteAll();

        // Create test data with multilingual names
        createTestItem("Chicken", "닭고기", AutocompleteType.MAIN_INGREDIENT, 80.0);
        createTestItem("Cheese", "치즈", AutocompleteType.SECONDARY_INGREDIENT, 70.0);
        createTestItem("Chili Powder", "고춧가루", AutocompleteType.SEASONING, 60.0);
        createTestItem("Chicken Curry", "치킨 카레", AutocompleteType.DISH, 90.0);
        createTestItem("Beef", "소고기", AutocompleteType.MAIN_INGREDIENT, 75.0);
        createTestItem("Onion", "양파", AutocompleteType.SECONDARY_INGREDIENT, 65.0);
        createTestItem("Salt", "소금", AutocompleteType.SEASONING, 85.0);
        createTestItem("Bibimbap", "비빔밥", AutocompleteType.DISH, 95.0);
    }

    private void createTestItem(String enName, String koName, AutocompleteType type, Double score) {
        createTestItemWithLocales(enName, koName, null, null, type, score);
    }

    private void createTestItemWithLocales(String enName, String koName, String jaName, String zhName,
                                           AutocompleteType type, Double score) {
        Map<String, String> names = new HashMap<>();
        names.put("en-US", enName);
        names.put("ko-KR", koName);
        if (jaName != null) names.put("ja-JP", jaName);
        if (zhName != null) names.put("zh-CN", zhName);

        AutocompleteItem item = AutocompleteItem.builder()
                .name(names)
                .type(type)
                .score(score)
                .build();
        autocompleteItemRepository.save(item);
    }

    @Nested
    @DisplayName("Search without type filter")
    class SearchWithoutType {

        @Test
        @DisplayName("should return matching items from all types")
        void shouldReturnMatchingItemsFromAllTypes() {
            List<AutocompleteDto> results = autocompleteService.search("Chi", "en-US", null);

            assertThat(results).isNotEmpty();
            assertThat(results).extracting(AutocompleteDto::name)
                    .contains("Chicken", "Chicken Curry", "Chili Powder");
        }

        @Test
        @DisplayName("should return empty list for non-matching keyword")
        void shouldReturnEmptyForNonMatchingKeyword() {
            List<AutocompleteDto> results = autocompleteService.search("xyz123", "en-US", null);

            assertThat(results).isEmpty();
        }

        @Test
        @DisplayName("should return empty list for blank keyword")
        void shouldReturnEmptyForBlankKeyword() {
            List<AutocompleteDto> results = autocompleteService.search("", "en-US", null);

            assertThat(results).isEmpty();
        }

        @Test
        @DisplayName("should return empty list for null keyword")
        void shouldReturnEmptyForNullKeyword() {
            List<AutocompleteDto> results = autocompleteService.search(null, "en-US", null);

            assertThat(results).isEmpty();
        }
    }

    @Nested
    @DisplayName("Search with DISH type")
    class SearchWithDishType {

        @Test
        @DisplayName("should return only dish items")
        void shouldReturnOnlyDishItems() {
            List<AutocompleteDto> results = autocompleteService.search("Chi", "en-US", "DISH");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).name()).isEqualTo("Chicken Curry");
            assertThat(results.get(0).type()).isEqualTo("DISH");
        }

        @Test
        @DisplayName("should return Korean dishes when using Korean locale")
        void shouldReturnKoreanDishes() {
            List<AutocompleteDto> results = autocompleteService.search("비빔", "ko-KR", "DISH");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).name()).isEqualTo("비빔밥");
        }
    }

    @Nested
    @DisplayName("Search with MAIN type (includes SECONDARY)")
    class SearchWithMainTypeIncludesSecondary {

        @Test
        @DisplayName("should return both main and secondary ingredient items")
        void shouldReturnBothMainAndSecondaryIngredients() {
            // Using 'Che' to match both Chicken (MAIN) and Cheese (SECONDARY)
            List<AutocompleteDto> results = autocompleteService.search("Che", "en-US", "MAIN");

            assertThat(results).isNotEmpty();
            // Should contain Chicken (MAIN) and Cheese (SECONDARY)
            assertThat(results).extracting(AutocompleteDto::type)
                    .containsAnyOf("MAIN_INGREDIENT", "SECONDARY_INGREDIENT");
        }

        @Test
        @DisplayName("should not return dishes or seasonings")
        void shouldNotReturnDishesOrSeasonings() {
            List<AutocompleteDto> results = autocompleteService.search("Che", "en-US", "MAIN");

            assertThat(results).extracting(AutocompleteDto::type)
                    .doesNotContain("DISH", "SEASONING");
        }

        @Test
        @DisplayName("should sort by score descending")
        void shouldSortByScoreDescending() {
            // Using 'Che' to get both Chicken (MAIN) and Cheese (SECONDARY)
            List<AutocompleteDto> results = autocompleteService.search("Che", "en-US", "MAIN");

            assertThat(results).isNotEmpty();
            // Verify sorted by score descending
            for (int i = 0; i < results.size() - 1; i++) {
                assertThat(results.get(i).score())
                        .isGreaterThanOrEqualTo(results.get(i + 1).score());
            }
        }
    }

    @Nested
    @DisplayName("Search with SECONDARY type (only SECONDARY)")
    class SearchWithSecondaryTypeOnly {

        @Test
        @DisplayName("should return only secondary ingredient items")
        void shouldReturnOnlySecondaryIngredients() {
            // Using 'Che' which matches Cheese (SECONDARY) but not Chicken (MAIN)
            List<AutocompleteDto> results = autocompleteService.search("Che", "en-US", "SECONDARY");

            assertThat(results).isNotEmpty();
            // Should contain only SECONDARY_INGREDIENT, not MAIN_INGREDIENT
            assertThat(results).extracting(AutocompleteDto::type)
                    .allMatch(type -> type.equals("SECONDARY_INGREDIENT"));
        }

        @Test
        @DisplayName("should not return main ingredients, dishes or seasonings")
        void shouldNotReturnMainDishesOrSeasonings() {
            List<AutocompleteDto> results = autocompleteService.search("Oni", "en-US", "SECONDARY");

            assertThat(results).extracting(AutocompleteDto::type)
                    .doesNotContain("MAIN_INGREDIENT", "DISH", "SEASONING");
        }
    }

    @Nested
    @DisplayName("Search with SEASONING type")
    class SearchWithSeasoningType {

        @Test
        @DisplayName("should return only seasoning items")
        void shouldReturnOnlySeasoningItems() {
            // pg_trgm requires at least 3 chars for effective fuzzy search
            List<AutocompleteDto> results = autocompleteService.search("Sal", "en-US", "SEASONING");

            assertThat(results).isNotEmpty();
            assertThat(results).extracting(AutocompleteDto::type)
                    .allMatch(type -> type.equals("SEASONING"));
        }

        @Test
        @DisplayName("should return Salt when searching for 'Salt'")
        void shouldReturnSaltWhenSearching() {
            List<AutocompleteDto> results = autocompleteService.search("Salt", "en-US", "SEASONING");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).name()).isEqualTo("Salt");
        }
    }

    @Nested
    @DisplayName("Multilingual support")
    class MultilingualSupport {

        @Test
        @DisplayName("should search in Korean with single character using prefix search")
        void shouldSearchInKoreanWithSingleChar() {
            // CJK locales should work with single characters using prefix search
            List<AutocompleteDto> results = autocompleteService.search("닭", "ko-KR", "MAIN");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).name()).isEqualTo("닭고기");
        }

        @Test
        @DisplayName("should search in Korean with full word")
        void shouldSearchInKoreanWithFullWord() {
            List<AutocompleteDto> results = autocompleteService.search("닭고기", "ko-KR", "MAIN");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).name()).isEqualTo("닭고기");
        }

        @Test
        @DisplayName("should search in English when using en-US locale")
        void shouldSearchInEnglish() {
            List<AutocompleteDto> results = autocompleteService.search("Beef", "en-US", "MAIN");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).name()).isEqualTo("Beef");
        }

        @Test
        @DisplayName("should return empty when searching wrong locale")
        void shouldReturnEmptyForWrongLocale() {
            // Searching Korean text with English locale
            List<AutocompleteDto> results = autocompleteService.search("닭고기", "en-US", "MAIN");

            assertThat(results).isEmpty();
        }

        @Test
        @DisplayName("should search Japanese with single character")
        void shouldSearchJapaneseWithSingleChar() {
            // Create Japanese test data with ja-JP locale
            createTestItemWithLocales("Sashimi", "사시미", "刺身", null, AutocompleteType.DISH, 85.0);

            List<AutocompleteDto> results = autocompleteService.search("刺", "ja-JP", "DISH");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).name()).isEqualTo("刺身");
        }

        @Test
        @DisplayName("should search Chinese with single character")
        void shouldSearchChineseWithSingleChar() {
            // Create Chinese test data with zh-CN locale
            createTestItemWithLocales("Fried Rice", "볶음밥", null, "炒饭", AutocompleteType.DISH, 85.0);

            List<AutocompleteDto> results = autocompleteService.search("炒", "zh-CN", "DISH");

            assertThat(results).hasSize(1);
            assertThat(results.get(0).name()).isEqualTo("炒饭");
        }
    }

    @Nested
    @DisplayName("Result limits")
    class ResultLimits {

        @BeforeEach
        void addMoreItems() {
            // Add many items to test limit
            for (int i = 0; i < 20; i++) {
                createTestItem("Test Item " + i, "테스트 아이템 " + i, AutocompleteType.DISH, 50.0 - i);
            }
        }

        @Test
        @DisplayName("should limit results to MAX_RESULTS (10)")
        void shouldLimitResults() {
            List<AutocompleteDto> results = autocompleteService.search("Test", "en-US", "DISH");

            assertThat(results).hasSizeLessThanOrEqualTo(10);
        }
    }

    @Nested
    @DisplayName("Case sensitivity")
    class CaseSensitivity {

        @Test
        @DisplayName("should match case-insensitively")
        void shouldMatchCaseInsensitively() {
            List<AutocompleteDto> lowerResults = autocompleteService.search("chicken", "en-US", "MAIN");
            List<AutocompleteDto> upperResults = autocompleteService.search("CHICKEN", "en-US", "MAIN");
            List<AutocompleteDto> mixedResults = autocompleteService.search("ChIcKeN", "en-US", "MAIN");

            assertThat(lowerResults).hasSizeGreaterThanOrEqualTo(1);
            assertThat(upperResults).hasSizeGreaterThanOrEqualTo(1);
            assertThat(mixedResults).hasSizeGreaterThanOrEqualTo(1);
        }
    }
}
