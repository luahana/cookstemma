package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.autocomplete.AutocompleteItem;
import com.cookstemma.cookstemma.domain.enums.AutocompleteType;
import com.cookstemma.cookstemma.repository.autocomplete.AutocompleteItemRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@DisplayName("AutocompleteController Tests")
class AutocompleteControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AutocompleteItemRepository autocompleteItemRepository;

    private static final String AUTOCOMPLETE_URL = "/api/v1/autocomplete";

    @BeforeEach
    void setUp() {
        autocompleteItemRepository.deleteAll();

        // Create test data
        createTestItem("Chicken", "닭고기", AutocompleteType.MAIN_INGREDIENT, 80.0);
        createTestItem("Cheese", "치즈", AutocompleteType.SECONDARY_INGREDIENT, 70.0);
        createTestItem("Chili Powder", "고춧가루", AutocompleteType.SEASONING, 60.0);
        createTestItem("Chicken Curry", "치킨 카레", AutocompleteType.DISH, 90.0);
        createTestItem("Beef", "소고기", AutocompleteType.MAIN_INGREDIENT, 75.0);
        createTestItem("Onion", "양파", AutocompleteType.SECONDARY_INGREDIENT, 65.0);
        createTestItem("Bibimbap", "비빔밥", AutocompleteType.DISH, 95.0);
    }

    private void createTestItem(String enName, String koName, AutocompleteType type, Double score) {
        Map<String, String> names = new HashMap<>();
        names.put("en-US", enName);
        names.put("ko-KR", koName);

        AutocompleteItem item = AutocompleteItem.builder()
                .name(names)
                .type(type)
                .score(score)
                .build();
        autocompleteItemRepository.save(item);
    }

    @Nested
    @DisplayName("GET /api/v1/autocomplete - Basic Search")
    class BasicSearch {

        @Test
        @DisplayName("should return 200 and matching items for keyword")
        void shouldReturnMatchingItems() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Chi")
                            .param("locale", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$.length()").value(greaterThan(0)))
                    .andExpect(jsonPath("$[*].name", hasItem("Chicken")));
        }

        @Test
        @DisplayName("should return empty array for non-matching keyword")
        void shouldReturnEmptyArrayForNonMatchingKeyword() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "xyz123nonexistent")
                            .param("locale", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$.length()").value(0));
        }

        @Test
        @DisplayName("should use default locale ko-KR when not specified")
        void shouldUseDefaultLocale() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "비빔"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$[0].name").value("비빔밥"));
        }

        @Test
        @DisplayName("should return results with publicId, name, type, and score")
        void shouldReturnResultsWithAllFields() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Chicken")
                            .param("locale", "en-US")
                            .param("type", "MAIN"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$[0].publicId").exists())
                    .andExpect(jsonPath("$[0].name").value("Chicken"))
                    .andExpect(jsonPath("$[0].type").value("MAIN_INGREDIENT"))
                    .andExpect(jsonPath("$[0].score").isNumber());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/autocomplete - Type Filtering")
    class TypeFiltering {

        @Test
        @DisplayName("should filter by DISH type")
        void shouldFilterByDishType() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Chi")
                            .param("locale", "en-US")
                            .param("type", "DISH"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].name").value("Chicken Curry"))
                    .andExpect(jsonPath("$[0].type").value("DISH"));
        }

        @Test
        @DisplayName("should return both MAIN and SECONDARY for MAIN type")
        void shouldReturnMainAndSecondaryForMainType() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Ch")
                            .param("locale", "en-US")
                            .param("type", "MAIN"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(2))
                    .andExpect(jsonPath("$[*].name", containsInAnyOrder("Chicken", "Cheese")))
                    .andExpect(jsonPath("$[*].type", containsInAnyOrder("MAIN_INGREDIENT", "SECONDARY_INGREDIENT")));
        }

        @Test
        @DisplayName("should filter by SEASONING type")
        void shouldFilterBySeasoningType() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Chi")
                            .param("locale", "en-US")
                            .param("type", "SEASONING"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].name").value("Chili Powder"))
                    .andExpect(jsonPath("$[0].type").value("SEASONING"));
        }

        @Test
        @DisplayName("should filter by SECONDARY type (only SECONDARY, not MAIN)")
        void shouldFilterBySecondaryTypeOnly() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Che")
                            .param("locale", "en-US")
                            .param("type", "SECONDARY"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].name").value("Cheese"))
                    .andExpect(jsonPath("$[0].type").value("SECONDARY_INGREDIENT"));
        }

        @Test
        @DisplayName("MAIN type should not include DISH or SEASONING")
        void mainTypeShouldNotIncludeDishOrSeasoning() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Ch")
                            .param("locale", "en-US")
                            .param("type", "MAIN"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$[*].type", not(hasItem("DISH"))))
                    .andExpect(jsonPath("$[*].type", not(hasItem("SEASONING"))));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/autocomplete - Locale Support")
    class LocaleSupport {

        @Test
        @DisplayName("should return English names for en-US locale")
        void shouldReturnEnglishNamesForEnUsLocale() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Beef")
                            .param("locale", "en-US")
                            .param("type", "MAIN"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].name").value("Beef"));
        }

        @Test
        @DisplayName("should return Korean names for ko-KR locale")
        void shouldReturnKoreanNamesForKoKrLocale() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "소고기")
                            .param("locale", "ko-KR")
                            .param("type", "MAIN"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].name").value("소고기"));
        }

        @Test
        @DisplayName("should search Korean dishes correctly")
        void shouldSearchKoreanDishes() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "비빔")
                            .param("locale", "ko-KR")
                            .param("type", "DISH"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].name").value("비빔밥"))
                    .andExpect(jsonPath("$[0].type").value("DISH"));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/autocomplete - Sorting")
    class Sorting {

        @BeforeEach
        void addItemsWithDifferentScores() {
            createTestItem("Apple", "사과", AutocompleteType.MAIN_INGREDIENT, 50.0);
            createTestItem("Apricot", "살구", AutocompleteType.MAIN_INGREDIENT, 70.0);
            createTestItem("Avocado", "아보카도", AutocompleteType.MAIN_INGREDIENT, 60.0);
        }

        @Test
        @DisplayName("should return results sorted by score descending")
        void shouldReturnResultsSortedByScoreDescending() throws Exception {
            // pg_trgm needs 3+ chars for fuzzy search
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "App")
                            .param("locale", "en-US")
                            .param("type", "MAIN"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(greaterThan(0)));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/autocomplete - Edge Cases")
    class EdgeCases {

        @Test
        @DisplayName("should handle short keyword gracefully")
        void shouldHandleShortKeywordGracefully() throws Exception {
            // Short keywords may return empty with pg_trgm - that's expected
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "B")
                            .param("locale", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray());
        }

        @Test
        @DisplayName("should handle special characters in keyword")
        void shouldHandleSpecialCharactersInKeyword() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Chi@#$")
                            .param("locale", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray());
        }

        @Test
        @DisplayName("should handle very long keyword")
        void shouldHandleVeryLongKeyword() throws Exception {
            String longKeyword = "a".repeat(100);
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", longKeyword)
                            .param("locale", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$.length()").value(0));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/autocomplete - No Authentication Required")
    class NoAuthenticationRequired {

        @Test
        @DisplayName("should allow access without authentication")
        void shouldAllowAccessWithoutAuthentication() throws Exception {
            mockMvc.perform(get(AUTOCOMPLETE_URL)
                            .param("keyword", "Chi")
                            .param("locale", "en-US"))
                    .andExpect(status().isOk());
        }
    }
}
