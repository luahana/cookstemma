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

import java.util.Map;
import java.util.Set;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class HashtagControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private HashtagRepository hashtagRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User koreanUser;
    private User englishUser;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        koreanUser = testUserFactory.createTestUser("korean_user", "ko-KR");
        englishUser = testUserFactory.createTestUser("english_user", "en-US");

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
        @DisplayName("Should return popular hashtags filtered by locale parameter")
        void getPopularHashtags_WithLocaleParam_ReturnsFilteredHashtags() throws Exception {
            // Create Korean recipe with Korean hashtag
            Hashtag koreanHashtag = Hashtag.builder().name("한식").build();
            hashtagRepository.save(koreanHashtag);

            Recipe koreanRecipe = Recipe.builder()
                    .title("김치찌개")
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(koreanHashtag))
                    .build();
            recipeRepository.save(koreanRecipe);

            // Create English recipe with English hashtag
            Hashtag englishHashtag = Hashtag.builder().name("vegan").build();
            hashtagRepository.save(englishHashtag);

            Recipe englishRecipe = Recipe.builder()
                    .title("Vegan Salad")
                    .description("Healthy vegan salad")
                    .cookingStyle("en-US")
                    .originalLanguage("en-US")
                    .foodMaster(testFood)
                    .creatorId(englishUser.getId())
                    .hashtags(Set.of(englishHashtag))
                    .build();
            recipeRepository.save(englishRecipe);

            // Request Korean hashtags
            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .param("locale", "ko-KR")
                            .param("limit", "10")
                            .param("minCount", "1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$", hasSize(1)))
                    .andExpect(jsonPath("$[0].name").value("한식"))
                    .andExpect(jsonPath("$[0].recipeCount").value(1));

            // Request English hashtags
            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .param("locale", "en-US")
                            .param("limit", "10")
                            .param("minCount", "1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$", hasSize(1)))
                    .andExpect(jsonPath("$[0].name").value("vegan"))
                    .andExpect(jsonPath("$[0].recipeCount").value(1));
        }

        @Test
        @DisplayName("Should use Accept-Language header when locale param is not provided")
        void getPopularHashtags_WithAcceptLanguage_ReturnsFilteredHashtags() throws Exception {
            // Create Korean recipe with Korean hashtag
            Hashtag koreanHashtag = Hashtag.builder().name("한식").build();
            hashtagRepository.save(koreanHashtag);

            Recipe koreanRecipe = Recipe.builder()
                    .title("김치찌개")
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(koreanHashtag))
                    .build();
            recipeRepository.save(koreanRecipe);

            // Request with Korean Accept-Language header
            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .header("Accept-Language", "ko-KR")
                            .param("limit", "10")
                            .param("minCount", "1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$", hasSize(1)))
                    .andExpect(jsonPath("$[0].name").value("한식"));
        }

        @Test
        @DisplayName("Should return empty list when no hashtags for locale")
        void getPopularHashtags_NoHashtagsForLocale_ReturnsEmptyList() throws Exception {
            // Create Korean recipe with Korean hashtag
            Hashtag koreanHashtag = Hashtag.builder().name("한식").build();
            hashtagRepository.save(koreanHashtag);

            Recipe koreanRecipe = Recipe.builder()
                    .title("김치찌개")
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(koreanHashtag))
                    .build();
            recipeRepository.save(koreanRecipe);

            // Request Japanese hashtags (none exist)
            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .param("locale", "ja-JP")
                            .param("limit", "10")
                            .param("minCount", "1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$", hasSize(0)));
        }

        @Test
        @DisplayName("Should respect limit parameter")
        void getPopularHashtags_WithLimit_RespectsLimit() throws Exception {
            // Create 5 hashtags with recipes
            for (int i = 0; i < 5; i++) {
                Hashtag hashtag = Hashtag.builder().name("태그" + i).build();
                hashtagRepository.save(hashtag);

                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .description("Description " + i)
                        .cookingStyle("ko-KR")
                        .originalLanguage("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(koreanUser.getId())
                        .hashtags(Set.of(hashtag))
                        .build();
                recipeRepository.save(recipe);
            }

            // Request with limit 2
            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .param("locale", "ko-KR")
                            .param("limit", "2")
                            .param("minCount", "1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$", hasSize(2)));
        }

        @Test
        @DisplayName("Should include totalCount in response")
        void getPopularHashtags_Response_IncludesTotalCount() throws Exception {
            Hashtag hashtag = Hashtag.builder().name("테스트").build();
            hashtagRepository.save(hashtag);

            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Description")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(hashtag))
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/hashtags/popular")
                            .param("locale", "ko-KR")
                            .param("limit", "10")
                            .param("minCount", "1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$[0].publicId").exists())
                    .andExpect(jsonPath("$[0].name").value("테스트"))
                    .andExpect(jsonPath("$[0].recipeCount").value(1))
                    .andExpect(jsonPath("$[0].logPostCount").value(0))
                    .andExpect(jsonPath("$[0].totalCount").value(1));
        }
    }
}
