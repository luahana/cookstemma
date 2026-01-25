package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.log_post.LogPostDetailResponseDto;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.log_post.UpdateLogRequestDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeDetailResponseDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.dto.recipe.UpdateRecipeRequestDto;
import com.cookstemma.cookstemma.dto.recipe.IngredientDto;
import com.cookstemma.cookstemma.dto.recipe.StepDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Tests for the private visibility feature.
 * Users can mark recipes and logs as private, making them visible only to themselves.
 */
class PrivateVisibilityTest extends BaseIntegrationTest {

    @Autowired
    private RecipeService recipeService;

    @Autowired
    private LogPostService logPostService;

    @Autowired
    private UserService userService;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User owner;
    private User otherUser;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        owner = testUserFactory.createTestUser("owner");
        otherUser = testUserFactory.createTestUser("other_user");

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    @Nested
    @DisplayName("Private Recipe Access Control Tests")
    class PrivateRecipeAccessTests {

        @Test
        @DisplayName("Owner can view their own private recipe")
        void getPrivateRecipe_AsOwner_Success() {
            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            RecipeDetailResponseDto result = recipeService.getRecipeDetail(
                    privateRecipe.getPublicId(),
                    owner.getId()
            );

            assertThat(result.title()).isEqualTo("Private Recipe");
            assertThat(result.isPrivate()).isTrue();
        }

        @Test
        @DisplayName("Non-owner cannot view private recipe")
        void getPrivateRecipe_AsNonOwner_ThrowsAccessDenied() {
            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            assertThatThrownBy(() -> recipeService.getRecipeDetail(
                    privateRecipe.getPublicId(),
                    otherUser.getId()
            )).isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("private");
        }

        @Test
        @DisplayName("Anonymous user cannot view private recipe")
        void getPrivateRecipe_AsAnonymous_ThrowsAccessDenied() {
            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            assertThatThrownBy(() -> recipeService.getRecipeDetail(
                    privateRecipe.getPublicId(),
                    null
            )).isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("private");
        }

        @Test
        @DisplayName("Anyone can view public recipe")
        void getPublicRecipe_AsAnyone_Success() {
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Recipe")
                    .description("Public description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            // Other user can view
            RecipeDetailResponseDto result = recipeService.getRecipeDetail(
                    publicRecipe.getPublicId(),
                    otherUser.getId()
            );
            assertThat(result.title()).isEqualTo("Public Recipe");

            // Anonymous can view
            RecipeDetailResponseDto anonymousResult = recipeService.getRecipeDetail(
                    publicRecipe.getPublicId(),
                    null
            );
            assertThat(anonymousResult.title()).isEqualTo("Public Recipe");
        }

        @Test
        @DisplayName("Private recipes should not appear in public feed")
        void privateRecipes_NotInPublicFeed() {
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Recipe")
                    .description("Public description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            Slice<RecipeSummaryDto> feed = recipeService.findRecipes(null, false, null, PageRequest.of(0, 10));

            assertThat(feed.getContent()).hasSize(1);
            assertThat(feed.getContent().get(0).title()).isEqualTo("Public Recipe");
        }
    }

    @Nested
    @DisplayName("Private Log Access Control Tests")
    class PrivateLogAccessTests {

        private Recipe testRecipe;

        @BeforeEach
        void setUpRecipe() {
            testRecipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .build();
            recipeRepository.save(testRecipe);
        }

        @Test
        @DisplayName("Owner can view their own private log")
        void getPrivateLog_AsOwner_Success() {
            LogPost privateLog = LogPost.builder()
                    .title("Private Log")
                    .content("Private content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(recipeLog);
            logPostRepository.save(privateLog);

            LogPostDetailResponseDto result = logPostService.getLogDetail(
                    privateLog.getPublicId(),
                    owner.getId()
            );

            assertThat(result.title()).isEqualTo("Private Log");
            assertThat(result.isPrivate()).isTrue();
        }

        @Test
        @DisplayName("Non-owner cannot view private log")
        void getPrivateLog_AsNonOwner_ThrowsAccessDenied() {
            LogPost privateLog = LogPost.builder()
                    .title("Private Log")
                    .content("Private content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(recipeLog);
            logPostRepository.save(privateLog);

            assertThatThrownBy(() -> logPostService.getLogDetail(
                    privateLog.getPublicId(),
                    otherUser.getId()
            )).isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("private");
        }

        @Test
        @DisplayName("Anonymous user cannot view private log")
        void getPrivateLog_AsAnonymous_ThrowsAccessDenied() {
            LogPost privateLog = LogPost.builder()
                    .title("Private Log")
                    .content("Private content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(recipeLog);
            logPostRepository.save(privateLog);

            assertThatThrownBy(() -> logPostService.getLogDetail(
                    privateLog.getPublicId(),
                    null
            )).isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("private");
        }

        @Test
        @DisplayName("Private logs should not appear in public feed")
        void privateLogs_NotInPublicFeed() {
            LogPost publicLog = LogPost.builder()
                    .title("Public Log")
                    .content("Public content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            RecipeLog publicRecipeLog = RecipeLog.builder()
                    .logPost(publicLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            publicLog.setRecipeLog(publicRecipeLog);
            logPostRepository.save(publicLog);

            LogPost privateLog = LogPost.builder()
                    .title("Private Log")
                    .content("Private content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            RecipeLog privateRecipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(privateRecipeLog);
            logPostRepository.save(privateLog);

            Slice<LogPostSummaryDto> feed = logPostService.getAllLogs(PageRequest.of(0, 10));

            assertThat(feed.getContent()).hasSize(1);
            assertThat(feed.getContent().get(0).title()).isEqualTo("Public Log");
        }
    }

    @Nested
    @DisplayName("Update Visibility Tests")
    class UpdateVisibilityTests {

        @Test
        @DisplayName("Should update log to private")
        void updateLogToPrivate_Success() {
            Recipe testRecipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .build();
            recipeRepository.save(testRecipe);

            LogPost publicLog = LogPost.builder()
                    .title("Public Log")
                    .content("Public content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(publicLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            publicLog.setRecipeLog(recipeLog);
            logPostRepository.save(publicLog);

            // Update to private
            UpdateLogRequestDto updateRequest = new UpdateLogRequestDto(
                    null,           // title
                    "Updated content",  // content
                    5,              // rating
                    null,           // hashtags
                    null,           // imagePublicIds
                    true            // isPrivate
            );

            LogPostDetailResponseDto result = logPostService.updateLog(
                    publicLog.getPublicId(),
                    updateRequest,
                    owner.getId()
            );

            assertThat(result.isPrivate()).isTrue();

            // Verify it's no longer in public feed
            Slice<LogPostSummaryDto> feed = logPostService.getAllLogs(PageRequest.of(0, 10));
            assertThat(feed.getContent()).isEmpty();
        }

        @Test
        @DisplayName("Should update log from private to public")
        void updateLogToPublic_Success() {
            Recipe testRecipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .build();
            recipeRepository.save(testRecipe);

            LogPost privateLog = LogPost.builder()
                    .title("Private Log")
                    .content("Private content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(recipeLog);
            logPostRepository.save(privateLog);

            // Update to public
            UpdateLogRequestDto updateRequest = new UpdateLogRequestDto(
                    null,           // title
                    "Updated content",  // content
                    5,              // rating
                    null,           // hashtags
                    null,           // imagePublicIds
                    false           // isPrivate
            );

            LogPostDetailResponseDto result = logPostService.updateLog(
                    privateLog.getPublicId(),
                    updateRequest,
                    owner.getId()
            );

            assertThat(result.isPrivate()).isFalse();

            // Verify it's now in public feed
            Slice<LogPostSummaryDto> feed = logPostService.getAllLogs(PageRequest.of(0, 10));
            assertThat(feed.getContent()).hasSize(1);
        }
    }

    @Nested
    @DisplayName("User Profile Visibility Filter Tests")
    class UserProfileVisibilityFilterTests {

        @Test
        @DisplayName("Should return only public recipes when visibility is 'public'")
        void getUserRecipes_PublicFilter() {
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Recipe")
                    .description("Public description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            Slice<RecipeSummaryDto> result = userService.getUserRecipes(
                    owner.getPublicId(),
                    null,
                    "public",
                    PageRequest.of(0, 10),
                    "ko"
            );

            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).title()).isEqualTo("Public Recipe");
        }

        @Test
        @DisplayName("Should return only private recipes when visibility is 'private'")
        void getUserRecipes_PrivateFilter() {
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Recipe")
                    .description("Public description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            Slice<RecipeSummaryDto> result = userService.getUserRecipes(
                    owner.getPublicId(),
                    null,
                    "private",
                    PageRequest.of(0, 10),
                    "ko"
            );

            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).title()).isEqualTo("Private Recipe");
        }

        @Test
        @DisplayName("Should return all recipes when visibility is 'all'")
        void getUserRecipes_AllFilter() {
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Recipe")
                    .description("Public description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            Slice<RecipeSummaryDto> result = userService.getUserRecipes(
                    owner.getPublicId(),
                    null,
                    "all",
                    PageRequest.of(0, 10),
                    "ko"
            );

            assertThat(result.getContent()).hasSize(2);
        }

        @Test
        @DisplayName("Using 'public' visibility filter should only return public recipes")
        void getUserRecipes_PublicFilterFromAnyViewer() {
            // This test verifies that the visibility filter works correctly
            // Access control for who can use which filter is handled at controller level
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Recipe")
                    .description("Public description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            // When using 'public' filter, only public recipes are returned
            Slice<RecipeSummaryDto> result = userService.getUserRecipes(
                    owner.getPublicId(),
                    null,
                    "public",
                    PageRequest.of(0, 10),
                    "ko"
            );

            // Should only see public recipe
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).title()).isEqualTo("Public Recipe");
        }

        @Test
        @DisplayName("Should return only public logs when visibility is 'public'")
        void getUserLogs_PublicFilter() {
            Recipe testRecipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .build();
            recipeRepository.save(testRecipe);

            LogPost publicLog = LogPost.builder()
                    .title("Public Log")
                    .content("Public content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            RecipeLog publicRecipeLog = RecipeLog.builder()
                    .logPost(publicLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            publicLog.setRecipeLog(publicRecipeLog);
            logPostRepository.save(publicLog);

            LogPost privateLog = LogPost.builder()
                    .title("Private Log")
                    .content("Private content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            RecipeLog privateRecipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(privateRecipeLog);
            logPostRepository.save(privateLog);

            Slice<LogPostSummaryDto> result = userService.getUserLogs(
                    owner.getPublicId(),
                    "public",
                    PageRequest.of(0, 10),
                    "ko"
            );

            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).title()).isEqualTo("Public Log");
        }

        @Test
        @DisplayName("Should return only private logs when visibility is 'private'")
        void getUserLogs_PrivateFilter() {
            Recipe testRecipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .build();
            recipeRepository.save(testRecipe);

            LogPost publicLog = LogPost.builder()
                    .title("Public Log")
                    .content("Public content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(false)
                    .build();
            RecipeLog publicRecipeLog = RecipeLog.builder()
                    .logPost(publicLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            publicLog.setRecipeLog(publicRecipeLog);
            logPostRepository.save(publicLog);

            LogPost privateLog = LogPost.builder()
                    .title("Private Log")
                    .content("Private content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            RecipeLog privateRecipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(privateRecipeLog);
            logPostRepository.save(privateLog);

            Slice<LogPostSummaryDto> result = userService.getUserLogs(
                    owner.getPublicId(),
                    "private",
                    PageRequest.of(0, 10),
                    "ko"
            );

            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).title()).isEqualTo("Private Log");
        }
    }

    @Nested
    @DisplayName("Summary DTO isPrivate Field Tests")
    class SummaryDtoTests {

        @Test
        @DisplayName("RecipeSummaryDto should include isPrivate field")
        void recipeSummaryDto_IncludesIsPrivate() {
            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .description("Private description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            Slice<RecipeSummaryDto> result = userService.getUserRecipes(
                    owner.getPublicId(),
                    null,
                    "all",
                    PageRequest.of(0, 10),
                    "ko"
            );

            assertThat(result.getContent()).hasSize(1);
            RecipeSummaryDto dto = result.getContent().get(0);
            assertThat(dto.isPrivate()).isTrue();
        }

        @Test
        @DisplayName("LogPostSummaryDto should include isPrivate field")
        void logPostSummaryDto_IncludesIsPrivate() {
            Recipe testRecipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(owner.getId())
                    .build();
            recipeRepository.save(testRecipe);

            LogPost privateLog = LogPost.builder()
                    .title("Private Log")
                    .content("Private content")
                    .locale("ko-KR")
                    .creatorId(owner.getId())
                    .isPrivate(true)
                    .build();
            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(recipeLog);
            logPostRepository.save(privateLog);

            Slice<LogPostSummaryDto> result = userService.getUserLogs(
                    owner.getPublicId(),
                    "all",
                    PageRequest.of(0, 10),
                    "ko"
            );

            assertThat(result.getContent()).hasSize(1);
            LogPostSummaryDto dto = result.getContent().get(0);
            assertThat(dto.isPrivate()).isTrue();
        }
    }
}
