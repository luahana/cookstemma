package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.search.SearchResultItem;
import com.cookstemma.cookstemma.dto.search.UnifiedSearchResponse;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.hashtag.HashtagRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class UnifiedSearchServiceTest extends BaseIntegrationTest {

    @Autowired
    private UnifiedSearchService unifiedSearchService;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private HashtagRepository hashtagRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

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
    @DisplayName("search() - Keyword Validation")
    class KeywordValidationTests {

        @Test
        @DisplayName("Should return empty response for null keyword")
        void search_NullKeyword_ReturnsEmpty() {
            UnifiedSearchResponse result = unifiedSearchService.search(null, "all", 0, 20, "en-US");

            assertThat(result.content()).isEmpty();
            assertThat(result.counts().total()).isZero();
        }

        @Test
        @DisplayName("Should return empty response for keyword shorter than 2 chars")
        void search_ShortKeyword_ReturnsEmpty() {
            UnifiedSearchResponse result = unifiedSearchService.search("a", "all", 0, 20, "en-US");

            assertThat(result.content()).isEmpty();
            assertThat(result.counts().total()).isZero();
        }

        @Test
        @DisplayName("Should trim keyword before searching")
        void search_TrimsKeyword() {
            Recipe recipe = Recipe.builder()
                    .title("Burger Recipe")
                    .description("Delicious burger")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            UnifiedSearchResponse result = unifiedSearchService.search("  burger  ", "recipes", 0, 20, "en-US");

            assertThat(result.counts().recipes()).isEqualTo(1);
        }
    }

    @Nested
    @DisplayName("search() - Type Filtering")
    class TypeFilteringTests {

        @Test
        @DisplayName("Should search all types when type is 'all'")
        void search_TypeAll_SearchesAllTypes() {
            // Create recipe
            Recipe recipe = Recipe.builder()
                    .title("Taco Tuesday")
                    .description("Weekly taco recipe")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Create hashtag
            Hashtag hashtag = Hashtag.builder()
                    .name("taco")
                    .build();
            hashtagRepository.save(hashtag);

            UnifiedSearchResponse result = unifiedSearchService.search("taco", "all", 0, 20, "en-US");

            assertThat(result.counts().recipes()).isEqualTo(1);
            assertThat(result.counts().hashtags()).isEqualTo(1);
            assertThat(result.counts().total()).isEqualTo(2);
        }

        @Test
        @DisplayName("Should search only recipes when type is 'recipes'")
        void search_TypeRecipes_SearchesOnlyRecipes() {
            // Create recipe
            Recipe recipe = Recipe.builder()
                    .title("Curry Recipe")
                    .description("Spicy curry")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Create hashtag with same name
            Hashtag hashtag = Hashtag.builder()
                    .name("curry")
                    .build();
            hashtagRepository.save(hashtag);

            UnifiedSearchResponse result = unifiedSearchService.search("curry", "recipes", 0, 20, "en-US");

            // Should only return recipe items, but counts should still include hashtags
            assertThat(result.content()).allMatch(item ->
                    item.type().equals(SearchResultItem.TYPE_RECIPE));
            assertThat(result.counts().recipes()).isEqualTo(1);
            assertThat(result.counts().hashtags()).isEqualTo(1); // Counts show all matching
        }

        @Test
        @DisplayName("Should search only logs when type is 'logs'")
        void search_TypeLogs_SearchesOnlyLogs() {
            // Create recipe first (needed for log)
            Recipe recipe = Recipe.builder()
                    .title("Base Recipe")
                    .description("Base description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Create log post
            LogPost logPost = LogPost.builder()
                    .title("Sushi making log")
                    .content("I made sushi today")
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

            UnifiedSearchResponse result = unifiedSearchService.search("sushi", "logs", 0, 20, "en-US");

            assertThat(result.content()).allMatch(item ->
                    item.type().equals(SearchResultItem.TYPE_LOG));
            assertThat(result.counts().logs()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should search only hashtags when type is 'hashtags'")
        void search_TypeHashtags_SearchesOnlyHashtags() {
            // Create recipe
            Recipe recipe = Recipe.builder()
                    .title("Ramen Recipe")
                    .description("Japanese ramen")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // Create hashtag
            Hashtag hashtag = Hashtag.builder()
                    .name("ramen")
                    .build();
            hashtagRepository.save(hashtag);

            UnifiedSearchResponse result = unifiedSearchService.search("ramen", "hashtags", 0, 20, "en-US");

            assertThat(result.content()).allMatch(item ->
                    item.type().equals(SearchResultItem.TYPE_HASHTAG));
            assertThat(result.counts().hashtags()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should default to 'all' when type is null")
        void search_NullType_DefaultsToAll() {
            Recipe recipe = Recipe.builder()
                    .title("Salad Recipe")
                    .description("Fresh salad")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            UnifiedSearchResponse result = unifiedSearchService.search("salad", null, 0, 20, "en-US");

            assertThat(result.counts().recipes()).isEqualTo(1);
        }
    }

    @Nested
    @DisplayName("search() - Counts")
    class CountsTests {

        @Test
        @DisplayName("Should return correct counts for each type")
        void search_ReturnsCorrectCountsForEachType() {
            // Create 2 recipes
            for (int i = 0; i < 2; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Pizza Recipe " + i)
                        .description("Italian pizza")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            // Create 1 hashtag
            Hashtag hashtag = Hashtag.builder()
                    .name("pizza")
                    .build();
            hashtagRepository.save(hashtag);

            UnifiedSearchResponse result = unifiedSearchService.search("pizza", "all", 0, 20, "en-US");

            assertThat(result.counts().recipes()).isEqualTo(2);
            assertThat(result.counts().logs()).isZero();
            assertThat(result.counts().hashtags()).isEqualTo(1);
            assertThat(result.counts().total()).isEqualTo(3);
        }

        @Test
        @DisplayName("Should return 0 counts when no matches")
        void search_NoMatches_ReturnsZeroCounts() {
            UnifiedSearchResponse result = unifiedSearchService.search("xyz123nonexistent", "all", 0, 20, "en-US");

            assertThat(result.counts().recipes()).isZero();
            assertThat(result.counts().logs()).isZero();
            assertThat(result.counts().hashtags()).isZero();
            assertThat(result.counts().total()).isZero();
        }
    }

    @Nested
    @DisplayName("search() - Pagination")
    class PaginationTests {

        @Test
        @DisplayName("Should respect page and size parameters")
        void search_RespectsPaginationParams() {
            // Create 5 recipes
            for (int i = 0; i < 5; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Steak Recipe " + i)
                        .description("Grilled steak")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            UnifiedSearchResponse result = unifiedSearchService.search("steak", "recipes", 0, 2, "ko-KR");

            assertThat(result.content()).hasSize(2);
            assertThat(result.page()).isZero();
            assertThat(result.size()).isEqualTo(2);
        }

        @Test
        @DisplayName("Should return hasNext=true when more results exist")
        void search_HasNextTrue_WhenMoreResultsExist() {
            // Create 5 recipes
            for (int i = 0; i < 5; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Sandwich Recipe " + i)
                        .description("Delicious sandwich")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            UnifiedSearchResponse result = unifiedSearchService.search("sandwich", "recipes", 0, 2, "en-US");

            assertThat(result.hasNext()).isTrue();
        }

        @Test
        @DisplayName("Should return hasNext=false on last page")
        void search_HasNextFalse_OnLastPage() {
            // Create 3 recipes
            for (int i = 0; i < 3; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Soup Recipe " + i)
                        .description("Hot soup")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            // Request page that includes all results
            UnifiedSearchResponse result = unifiedSearchService.search("soup", "recipes", 0, 10, "en-US");

            assertThat(result.hasNext()).isFalse();
        }

        @Test
        @DisplayName("Should calculate totalPages correctly")
        void search_CalculatesTotalPagesCorrectly() {
            // Create 7 recipes
            for (int i = 0; i < 7; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Bread Recipe " + i)
                        .description("Fresh bread")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            UnifiedSearchResponse result = unifiedSearchService.search("bread", "recipes", 0, 3, "en-US");

            assertThat(result.totalPages()).isEqualTo(3); // 7 items / 3 per page = 3 pages
            assertThat(result.totalElements()).isEqualTo(7);
        }
    }

    @Nested
    @DisplayName("search() - Result Conversion")
    class ResultConversionTests {

        @Test
        @DisplayName("Should convert Recipe to RecipeSummaryDto correctly")
        void search_ConvertsRecipeToDto() {
            Recipe recipe = Recipe.builder()
                    .title("Pasta Carbonara")
                    .description("Classic Italian pasta")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            UnifiedSearchResponse result = unifiedSearchService.search("carbonara", "recipes", 0, 20, "ko-KR");

            assertThat(result.content()).hasSize(1);
            SearchResultItem item = result.content().get(0);
            assertThat(item.type()).isEqualTo(SearchResultItem.TYPE_RECIPE);
            assertThat(item.relevanceScore()).isNotNull();
            assertThat(item.data()).isNotNull();
        }

        @Test
        @DisplayName("Should convert LogPost to LogPostSummaryDto correctly")
        void search_ConvertsLogToDto() {
            Recipe recipe = Recipe.builder()
                    .title("Base Recipe")
                    .description("Base description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            LogPost logPost = LogPost.builder()
                    .title("Risotto cooking attempt")
                    .content("Made risotto for dinner")
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

            UnifiedSearchResponse result = unifiedSearchService.search("risotto", "logs", 0, 20, "ko-KR");

            assertThat(result.content()).hasSize(1);
            SearchResultItem item = result.content().get(0);
            assertThat(item.type()).isEqualTo(SearchResultItem.TYPE_LOG);
            assertThat(item.relevanceScore()).isNotNull();
            assertThat(item.data()).isNotNull();
        }

        @Test
        @DisplayName("Should convert Hashtag to HashtagSearchDto with counts")
        void search_ConvertsHashtagToDto() {
            // Create hashtag first
            Hashtag hashtag = Hashtag.builder()
                    .name("dessert")
                    .build();
            hashtagRepository.save(hashtag);

            // Create recipe with hashtag
            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(hashtag);

            Recipe recipe = Recipe.builder()
                    .title("Chocolate Cake")
                    .description("Sweet dessert")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(hashtags)
                    .build();
            recipeRepository.save(recipe);

            UnifiedSearchResponse result = unifiedSearchService.search("dessert", "hashtags", 0, 20, "en-US");

            assertThat(result.content()).hasSize(1);
            SearchResultItem item = result.content().get(0);
            assertThat(item.type()).isEqualTo(SearchResultItem.TYPE_HASHTAG);
            assertThat(item.relevanceScore()).isNotNull();
            assertThat(item.data()).isNotNull();
        }
    }

    @Nested
    @DisplayName("search() - Relevance Scoring")
    class RelevanceScoringTests {

        @Test
        @DisplayName("Should give exact hashtag match highest relevance")
        void search_ExactHashtagMatch_HighestRelevance() {
            // Create exact match hashtag
            Hashtag exactMatch = Hashtag.builder()
                    .name("korean")
                    .build();
            hashtagRepository.save(exactMatch);

            // Create prefix match hashtag
            Hashtag prefixMatch = Hashtag.builder()
                    .name("koreanfood")
                    .build();
            hashtagRepository.save(prefixMatch);

            UnifiedSearchResponse result = unifiedSearchService.search("korean", "hashtags", 0, 20, "en-US");

            assertThat(result.content()).hasSizeGreaterThanOrEqualTo(1);
            // Exact match should have higher or equal relevance
            SearchResultItem firstItem = result.content().get(0);
            assertThat(firstItem.relevanceScore()).isGreaterThanOrEqualTo(0.9);
        }

        @Test
        @DisplayName("Should include relevance score in all results")
        void search_AllResultsHaveRelevanceScore() {
            Recipe recipe = Recipe.builder()
                    .title("Waffle Recipe")
                    .description("Belgian waffles")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            UnifiedSearchResponse result = unifiedSearchService.search("waffle", "all", 0, 20, "en-US");

            assertThat(result.content()).allMatch(item ->
                    item.relevanceScore() != null && item.relevanceScore() > 0);
        }
    }

    @Nested
    @DisplayName("search() - Edge Cases")
    class EdgeCaseTests {

        @Test
        @DisplayName("Should handle empty results gracefully")
        void search_EmptyResults_ReturnsValidResponse() {
            UnifiedSearchResponse result = unifiedSearchService.search("veryrandomnonexistent", "all", 0, 20, "en-US");

            assertThat(result).isNotNull();
            assertThat(result.content()).isEmpty();
            assertThat(result.counts()).isNotNull();
            assertThat(result.page()).isZero();
        }

        @Test
        @DisplayName("Should handle whitespace-only keyword")
        void search_WhitespaceKeyword_ReturnsEmpty() {
            UnifiedSearchResponse result = unifiedSearchService.search("   ", "all", 0, 20, "en-US");

            assertThat(result.content()).isEmpty();
            assertThat(result.counts().total()).isZero();
        }

        @Test
        @DisplayName("Should handle unknown type parameter gracefully")
        void search_UnknownType_DefaultsToAll() {
            Recipe recipe = Recipe.builder()
                    .title("Pancake Recipe")
                    .description("Fluffy pancakes")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            UnifiedSearchResponse result = unifiedSearchService.search("pancake", "unknown_type", 0, 20, "en-US");

            // Should default to "all" behavior
            assertThat(result.counts().recipes()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should not include deleted content in results")
        void search_ExcludesDeletedContent() {
            // Create and delete recipe
            Recipe deletedRecipe = Recipe.builder()
                    .title("Deleted Omelette")
                    .description("This was deleted")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            deletedRecipe.softDelete();
            recipeRepository.save(deletedRecipe);

            // Create active recipe
            Recipe activeRecipe = Recipe.builder()
                    .title("Active Omelette")
                    .description("This is active")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(activeRecipe);

            UnifiedSearchResponse result = unifiedSearchService.search("omelette", "recipes", 0, 20, "ko-KR");

            assertThat(result.counts().recipes()).isEqualTo(1);
            assertThat(result.content()).hasSize(1);
        }

        @Test
        @DisplayName("Should not include private content in results")
        void search_ExcludesPrivateContent() {
            // Create private recipe
            Recipe privateRecipe = Recipe.builder()
                    .title("Private Muffin")
                    .description("Secret recipe")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            // Create public recipe
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Muffin")
                    .description("Everyone can see")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            UnifiedSearchResponse result = unifiedSearchService.search("muffin", "recipes", 0, 20, "en-US");

            assertThat(result.counts().recipes()).isEqualTo(1);
        }
    }
}
