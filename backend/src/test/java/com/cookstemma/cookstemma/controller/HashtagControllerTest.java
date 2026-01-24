package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.hashtag.HashtagRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class HashtagControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private HashtagRepository hashtagRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    private User testUser;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    @Nested
    @DisplayName("GET /api/v1/hashtags/popular")
    class GetPopularHashtagsTests {

        @Test
        @DisplayName("Should return empty list when no hashtags exist")
        void getPopularHashtags_NoHashtags_ReturnsEmpty() throws Exception {
            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .header("Accept-Language", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$").isEmpty());
        }

        @Test
        @DisplayName("Should return popular hashtags filtered by English locale")
        void getPopularHashtags_EnglishLocale_ReturnsEnglishHashtags() throws Exception {
            // Create hashtag and English recipe
            Hashtag veganTag = Hashtag.builder().name("vegan").build();
            hashtagRepository.save(veganTag);

            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(veganTag);

            Recipe recipe = Recipe.builder()
                    .title("Vegan Salad")
                    .titleTranslations(Map.of("en-US", "Vegan Salad"))
                    .description("Healthy salad")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(hashtags)
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .header("Accept-Language", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$[0].name").value("vegan"))
                    .andExpect(jsonPath("$[0].recipeCount").value(1))
                    .andExpect(jsonPath("$[0].totalCount").value(1));
        }

        @Test
        @DisplayName("Should return popular hashtags filtered by Korean locale")
        void getPopularHashtags_KoreanLocale_ReturnsKoreanHashtags() throws Exception {
            // Create hashtag with Korean recipe
            Hashtag koreanTag = Hashtag.builder().name("한식").build();
            hashtagRepository.save(koreanTag);

            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(koreanTag);

            Recipe recipe = Recipe.builder()
                    .title("김치찌개")
                    .titleTranslations(Map.of("ko-KR", "김치찌개"))
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(hashtags)
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .header("Accept-Language", "ko-KR"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$[0].name").value("한식"));
        }

        @Test
        @DisplayName("Should respect limit parameter")
        void getPopularHashtags_WithLimit_ReturnsLimitedResults() throws Exception {
            // Create 5 hashtags with recipes
            for (int i = 0; i < 5; i++) {
                Hashtag tag = Hashtag.builder().name("tag" + i).build();
                hashtagRepository.save(tag);

                Set<Hashtag> hashtags = new HashSet<>();
                hashtags.add(tag);

                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .titleTranslations(Map.of("en-US", "Recipe " + i))
                        .description("Description")
                        .cookingStyle("en-US")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .hashtags(hashtags)
                        .build();
                recipeRepository.save(recipe);
            }

            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .param("limit", "3")
                            .header("Accept-Language", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$.length()").value(3));
        }

        @Test
        @DisplayName("Should respect minCount parameter")
        void getPopularHashtags_WithMinCount_FiltersLowCounts() throws Exception {
            // Create hashtag with 1 recipe
            Hashtag lowCountTag = Hashtag.builder().name("lowcount").build();
            hashtagRepository.save(lowCountTag);

            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(lowCountTag);

            Recipe recipe = Recipe.builder()
                    .title("Single Recipe")
                    .titleTranslations(Map.of("en-US", "Single Recipe"))
                    .description("Description")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(hashtags)
                    .build();
            recipeRepository.save(recipe);

            // With minCount=2, should not return the hashtag
            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .param("minCount", "2")
                            .header("Accept-Language", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$").isEmpty());
        }

        @Test
        @DisplayName("Should return hashtags with publicId, name, and counts")
        void getPopularHashtags_ReturnsCorrectFields() throws Exception {
            Hashtag tag = Hashtag.builder().name("testtag").build();
            hashtagRepository.save(tag);

            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(tag);

            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .titleTranslations(Map.of("en-US", "Test Recipe"))
                    .description("Description")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(hashtags)
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .header("Accept-Language", "en-US"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$[0].publicId").exists())
                    .andExpect(jsonPath("$[0].name").value("testtag"))
                    .andExpect(jsonPath("$[0].recipeCount").value(1))
                    .andExpect(jsonPath("$[0].logPostCount").value(0))
                    .andExpect(jsonPath("$[0].totalCount").value(1));
        }
    }
}
