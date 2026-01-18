package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.hashtag.HashtagRepository;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.support.BaseIntegrationTest;
import com.pairingplanet.pairing_planet.support.TestJwtTokenProvider;
import com.pairingplanet.pairing_planet.support.TestUserFactory;
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

class SearchControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private HashtagRepository hashtagRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    private User testUser;
    private FoodMaster testFood;
    private String authToken;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();
        authToken = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "김치", "en-US", "Kimchi"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    @Nested
    @DisplayName("GET /api/v1/search")
    class SearchTests {

        @Test
        @DisplayName("Should return empty when keyword is too short (< 2 chars)")
        void search_KeywordTooShort_ReturnsEmpty() throws Exception {
            mockMvc.perform(get("/api/v1/search")
                            .param("q", "a"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isEmpty())
                    .andExpect(jsonPath("$.counts.total").value(0));
        }

        @Test
        @DisplayName("Should return recipes when type=recipes")
        void search_TypeRecipes_ReturnsOnlyRecipes() throws Exception {
            // Create searchable recipe
            Recipe recipe = Recipe.builder()
                    .title("Kimchi Fried Rice")
                    .description("Delicious fried rice")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "Kimchi")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should return logs when type=logs")
        void search_TypeLogs_ReturnsOnlyLogs() throws Exception {
            // Create recipe first
            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Create log post with "kimchi" in title
            LogPost logPost = LogPost.builder()
                    .title("My kimchi cooking log")
                    .content("I made kimchi today")
                    .locale("ko-KR")
                    .creatorId(testUser.getId())
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(logPost)
                    .recipe(recipe)
                    .rating(5)
                    .build();
            logPost.setRecipeLog(recipeLog);
            logPostRepository.save(logPost);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "kimchi")
                            .param("type", "logs"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.counts.logs").value(1));
        }

        @Test
        @DisplayName("Should return hashtags when type=hashtags")
        void search_TypeHashtags_ReturnsOnlyHashtags() throws Exception {
            // Create hashtag
            Hashtag hashtag = Hashtag.builder()
                    .name("kimchi")
                    .build();
            hashtagRepository.save(hashtag);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "kimchi")
                            .param("type", "hashtags"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.counts.hashtags").value(1));
        }

        @Test
        @DisplayName("Should return mixed results when type=all (default)")
        void search_TypeAll_ReturnsMixedResults() throws Exception {
            // Create recipe
            Recipe recipe = Recipe.builder()
                    .title("Kimchi Stew")
                    .description("Traditional Korean stew")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Create hashtag
            Hashtag hashtag = Hashtag.builder()
                    .name("kimchi")
                    .build();
            hashtagRepository.save(hashtag);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "kimchi"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.counts.recipes").value(1))
                    .andExpect(jsonPath("$.counts.hashtags").value(1));
        }

        @Test
        @DisplayName("Should return correct counts in response")
        void search_ReturnsCorrectCounts() throws Exception {
            // Create 2 recipes
            for (int i = 0; i < 2; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Pasta Recipe " + i)
                        .description("Delicious pasta")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            // Create 1 hashtag
            Hashtag hashtag = Hashtag.builder()
                    .name("pasta")
                    .build();
            hashtagRepository.save(hashtag);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "pasta"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(2))
                    .andExpect(jsonPath("$.counts.hashtags").value(1))
                    .andExpect(jsonPath("$.counts.total").value(3));
        }

        @Test
        @DisplayName("Should support pagination (page, size params)")
        void search_Pagination_Works() throws Exception {
            // Create 5 recipes
            for (int i = 0; i < 5; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Rice Recipe " + i)
                        .description("Delicious rice dish")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            // Request page 0 with size 2
            mockMvc.perform(get("/api/v1/search")
                            .param("q", "rice")
                            .param("type", "recipes")
                            .param("page", "0")
                            .param("size", "2"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content.length()").value(2))
                    .andExpect(jsonPath("$.page").value(0))
                    .andExpect(jsonPath("$.size").value(2))
                    .andExpect(jsonPath("$.hasNext").value(true));
        }

        @Test
        @DisplayName("Should be case-insensitive")
        void search_CaseInsensitive_ReturnsResults() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("SPAGHETTI Carbonara")
                    .description("Classic Italian pasta")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Search with lowercase
            mockMvc.perform(get("/api/v1/search")
                            .param("q", "spaghetti")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should handle special characters in query")
        void search_SpecialCharacters_HandlesGracefully() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("Tom & Jerry's Pizza")
                    .description("Special pizza recipe")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "Tom")
                            .param("type", "recipes"))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Should return empty when no matches found")
        void search_NoMatches_ReturnsEmptyContent() throws Exception {
            mockMvc.perform(get("/api/v1/search")
                            .param("q", "nonexistentfood123"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isEmpty())
                    .andExpect(jsonPath("$.counts.total").value(0));
        }

        @Test
        @DisplayName("Should not return private recipes")
        void search_ExcludesPrivateRecipes() throws Exception {
            // Create public recipe
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Noodle Recipe")
                    .description("Everyone can see this")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            // Create private recipe
            Recipe privateRecipe = Recipe.builder()
                    .title("Private Noodle Recipe")
                    .description("Only I can see this")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "noodle")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should not return deleted recipes")
        void search_ExcludesDeletedRecipes() throws Exception {
            // Create and soft-delete a recipe
            Recipe deletedRecipe = Recipe.builder()
                    .title("Deleted Soup Recipe")
                    .description("This was deleted")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            deletedRecipe.softDelete();
            recipeRepository.save(deletedRecipe);

            // Create active recipe
            Recipe activeRecipe = Recipe.builder()
                    .title("Active Soup Recipe")
                    .description("This is still active")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(activeRecipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "soup")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should search recipes by description")
        void search_MatchesDescription() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("Simple Dish")
                    .description("Made with special avocado sauce")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "avocado")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should return recipes with hashtag in response")
        void search_RecipeWithHashtags_IncludesHashtags() throws Exception {
            // Create hashtag
            Hashtag hashtag = Hashtag.builder()
                    .name("spicy")
                    .build();
            hashtagRepository.save(hashtag);

            // Create recipe with hashtag
            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(hashtag);

            Recipe recipe = Recipe.builder()
                    .title("Spicy Chicken Wings")
                    .description("Very hot wings")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(hashtags)
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "chicken")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }
    }
}
