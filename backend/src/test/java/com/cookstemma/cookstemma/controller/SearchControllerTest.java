package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.hashtag.HashtagRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
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
                            .header("Accept-Language", "ko-KR")
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

    @Nested
    @DisplayName("GET /api/v1/search - Multi-language Search")
    class MultiLanguageSearchTests {

        @Test
        @DisplayName("Should find recipe by Korean title translation")
        void search_KoreanTitleTranslation_ReturnsRecipe() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("Curry Rice")
                    .titleTranslations(Map.of("ko-KR", "카레 라이스", "en-US", "Curry Rice"))
                    .description("Delicious curry")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "카레")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should find recipe by English title translation when base title is Korean")
        void search_EnglishTitleTranslation_ReturnsRecipe() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("김치찌개")
                    .titleTranslations(Map.of("ko-KR", "김치찌개", "en-US", "Kimchi Stew"))
                    .description("Traditional Korean stew")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "Stew")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should find recipe by description translation")
        void search_DescriptionTranslation_ReturnsRecipe() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("Bibimbap")
                    .description("Mixed rice bowl")
                    .descriptionTranslations(Map.of("ko-KR", "비빔밥은 맛있는 한국 요리입니다", "en-US", "Mixed rice bowl"))
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "비빔밥")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should find recipe by FoodMaster Korean name")
        void search_FoodMasterKoreanName_ReturnsRecipe() throws Exception {
            // Create food with multilingual name
            FoodMaster curryFood = FoodMaster.builder()
                    .name(Map.of("ko-KR", "카레", "en-US", "Curry", "ja-JP", "カレー"))
                    .isVerified(true)
                    .build();
            foodMasterRepository.save(curryFood);

            Recipe recipe = Recipe.builder()
                    .title("Curry Dish")
                    .description("A curry based dish")
                    .cookingStyle("ko-KR")
                    .foodMaster(curryFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Search by Korean food name
            mockMvc.perform(get("/api/v1/search")
                            .param("q", "카레")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should find recipe by FoodMaster Japanese name")
        void search_FoodMasterJapaneseName_ReturnsRecipe() throws Exception {
            // Create food with multilingual name including Japanese
            FoodMaster ramenFood = FoodMaster.builder()
                    .name(Map.of("ko-KR", "라멘", "en-US", "Ramen", "ja-JP", "ラーメン"))
                    .isVerified(true)
                    .build();
            foodMasterRepository.save(ramenFood);

            Recipe recipe = Recipe.builder()
                    .title("Ramen")
                    .description("Japanese noodle soup")
                    .cookingStyle("ja-JP")
                    .foodMaster(ramenFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Search by Japanese food name
            mockMvc.perform(get("/api/v1/search")
                            .param("q", "ラーメン")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(1));
        }

        @Test
        @DisplayName("Should find log post by Korean title translation")
        void search_LogPostKoreanTitleTranslation_ReturnsLog() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            LogPost logPost = LogPost.builder()
                    .title("My Cooking Log")
                    .titleTranslations(Map.of("ko-KR", "나의 요리 일지", "en-US", "My Cooking Log"))
                    .content("Today I made something")
                    .locale("en-US")
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
                            .param("q", "요리 일지")
                            .param("type", "logs"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.logs").value(1));
        }

        @Test
        @DisplayName("Should find log post by content translation")
        void search_LogPostContentTranslation_ReturnsLog() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            LogPost logPost = LogPost.builder()
                    .title("Cooking Experience")
                    .content("I tried the recipe")
                    .contentTranslations(Map.of("ko-KR", "레시피를 시도해봤습니다. 정말 맛있었어요!", "en-US", "I tried the recipe"))
                    .locale("en-US")
                    .creatorId(testUser.getId())
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(logPost)
                    .recipe(recipe)
                    .rating(4)
                    .build();
            logPost.setRecipeLog(recipeLog);
            logPostRepository.save(logPost);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "맛있었어요")
                            .param("type", "logs"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.logs").value(1));
        }

        @Test
        @DisplayName("Should find recipe via linked recipe title translation in log search")
        void search_LinkedRecipeTitleTranslation_ReturnsLog() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("Tteokbokki")
                    .titleTranslations(Map.of("ko-KR", "떡볶이", "en-US", "Spicy Rice Cakes"))
                    .description("Korean street food")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            LogPost logPost = LogPost.builder()
                    .title("My experience")
                    .content("Made this today")
                    .locale("en-US")
                    .creatorId(testUser.getId())
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(logPost)
                    .recipe(recipe)
                    .rating(5)
                    .build();
            logPost.setRecipeLog(recipeLog);
            logPostRepository.save(logPost);

            // Search by Korean recipe title - should find the log
            mockMvc.perform(get("/api/v1/search")
                            .param("q", "떡볶이")
                            .param("type", "logs"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.logs").value(1));
        }

        @Test
        @DisplayName("Should find multiple recipes across different language translations")
        void search_MultipleLanguages_ReturnsAllMatches() throws Exception {
            // Recipe 1: Korean title contains "치킨"
            Recipe recipe1 = Recipe.builder()
                    .title("Fried Chicken")
                    .titleTranslations(Map.of("ko-KR", "후라이드 치킨", "en-US", "Fried Chicken"))
                    .description("Crispy chicken")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe1);

            // Recipe 2: Korean description contains "치킨"
            Recipe recipe2 = Recipe.builder()
                    .title("Korean BBQ")
                    .descriptionTranslations(Map.of("ko-KR", "맛있는 치킨과 함께", "en-US", "With delicious chicken"))
                    .description("BBQ style")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe2);

            mockMvc.perform(get("/api/v1/search")
                            .param("q", "치킨")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(2));
        }

        @Test
        @DisplayName("Should not find recipe when translation doesn't match")
        void search_NoMatchingTranslation_ReturnsEmpty() throws Exception {
            Recipe recipe = Recipe.builder()
                    .title("Pasta")
                    .titleTranslations(Map.of("ko-KR", "파스타", "en-US", "Pasta"))
                    .description("Italian pasta")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Search for unrelated Korean term
            mockMvc.perform(get("/api/v1/search")
                            .param("q", "초밥")
                            .param("type", "recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.counts.recipes").value(0));
        }
    }
}
