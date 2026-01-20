package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.log_post.LogPostDetailResponseDto;
import com.cookstemma.cookstemma.dto.log_post.UpdateLogRequestDto;
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
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LogPostServiceTest extends BaseIntegrationTest {

    @Autowired
    private LogPostService logPostService;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;
    private User otherUser;
    private Recipe testRecipe;
    private LogPost testLogPost;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();
        otherUser = testUserFactory.createTestUser("other_user");

        FoodMaster food = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(food);

        testRecipe = Recipe.builder()
                .title("Test Recipe")
                .description("Test Description")
                .cookingStyle("ko-KR")
                .foodMaster(food)
                .creatorId(testUser.getId())
                .build();
        recipeRepository.save(testRecipe);

        // Create a log post with RecipeLog
        testLogPost = LogPost.builder()
                .title("Test Log")
                .content("Original content")
                .locale("ko-KR")
                .creatorId(testUser.getId())
                .build();

        RecipeLog recipeLog = RecipeLog.builder()
                .logPost(testLogPost)
                .recipe(testRecipe)
                .rating(5)
                .build();
        testLogPost.setRecipeLog(recipeLog);

        logPostRepository.save(testLogPost);
    }

    @Nested
    @DisplayName("Update Log Post")
    class UpdateLogTests {

        @Test
        @DisplayName("Should update log post when user is the owner")
        void updateLog_AsOwner_Success() {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars (equivalent to PARTIAL)
                    List.of("tag1", "tag2"),
                    null
            );

            LogPostDetailResponseDto result = logPostService.updateLog(
                    testLogPost.getPublicId(),
                    request,
                    testUser.getId()
            );

            assertThat(result.content()).isEqualTo("Updated content");
            assertThat(result.rating()).isEqualTo(3);

            // Verify in database
            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getContent()).isEqualTo("Updated content");
            assertThat(updated.getRecipeLog().getRating()).isEqualTo(3);
        }

        @Test
        @DisplayName("Should throw AccessDeniedException when user is not the owner")
        void updateLog_NotOwner_ThrowsException() {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars
                    null,
                    null
            );

            assertThatThrownBy(() -> logPostService.updateLog(
                    testLogPost.getPublicId(),
                    request,
                    otherUser.getId()
            )).isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("not the owner");
        }

        @Test
        @DisplayName("Should throw exception when log post not found")
        void updateLog_NotFound_ThrowsException() {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars
                    null,
                    null
            );

            assertThatThrownBy(() -> logPostService.updateLog(
                    java.util.UUID.randomUUID(),
                    request,
                    testUser.getId()
            )).isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not found");
        }

        @Test
        @DisplayName("Should clear hashtags when null is passed")
        void updateLog_NullHashtags_ClearsHashtags() {
            // First add some hashtags
            UpdateLogRequestDto addTagsRequest = new UpdateLogRequestDto(
                    null,
                    "Content with tags",
                    5,  // 5 stars
                    List.of("tag1", "tag2"),
                    null
            );
            logPostService.updateLog(testLogPost.getPublicId(), addTagsRequest, testUser.getId());

            // Then clear them
            UpdateLogRequestDto clearTagsRequest = new UpdateLogRequestDto(
                    null,
                    "Content without tags",
                    5,  // 5 stars
                    null,
                    null
            );
            logPostService.updateLog(testLogPost.getPublicId(), clearTagsRequest, testUser.getId());

            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getHashtags()).isEmpty();
        }
    }

    @Nested
    @DisplayName("Delete Log Post")
    class DeleteLogTests {

        @Test
        @DisplayName("Should soft delete log post when user is the owner")
        void deleteLog_AsOwner_Success() {
            logPostService.deleteLog(testLogPost.getPublicId(), testUser.getId());

            LogPost deleted = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(deleted.isDeleted()).isTrue();
        }

        @Test
        @DisplayName("Should throw AccessDeniedException when user is not the owner")
        void deleteLog_NotOwner_ThrowsException() {
            assertThatThrownBy(() -> logPostService.deleteLog(
                    testLogPost.getPublicId(),
                    otherUser.getId()
            )).isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("not the owner");
        }

        @Test
        @DisplayName("Should throw exception when log post not found")
        void deleteLog_NotFound_ThrowsException() {
            assertThatThrownBy(() -> logPostService.deleteLog(
                    java.util.UUID.randomUUID(),
                    testUser.getId()
            )).isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not found");
        }
    }

    @Nested
    @DisplayName("Get Log Detail with creatorPublicId")
    class GetLogDetailTests {

        @Test
        @DisplayName("Should return creatorPublicId in response")
        void getLogDetail_ReturnsCreatorPublicId() {
            LogPostDetailResponseDto result = logPostService.getLogDetail(
                    testLogPost.getPublicId(),
                    testUser.getId()
            );

            assertThat(result.creatorPublicId()).isEqualTo(testUser.getPublicId());
        }
    }

    @Nested
    @DisplayName("Get Logs By Recipe")
    class GetLogsByRecipeTests {

        @Test
        @DisplayName("Should return logs for a specific recipe")
        void getLogsByRecipe_ReturnsLogs() {
            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);
            var result = logPostService.getLogsByRecipe(testRecipe.getPublicId(), pageable, "en");

            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).publicId()).isEqualTo(testLogPost.getPublicId());
        }

        @Test
        @DisplayName("Should return empty when recipe has no logs")
        void getLogsByRecipe_NoLogs_ReturnsEmpty() {
            // Create a recipe without logs
            FoodMaster food2 = FoodMaster.builder()
                    .name(Map.of("ko-KR", "다른음식"))
                    .isVerified(true)
                    .build();
            foodMasterRepository.save(food2);

            Recipe recipeWithNoLogs = Recipe.builder()
                    .title("Recipe Without Logs")
                    .description("No logs here")
                    .cookingStyle("ko-KR")
                    .foodMaster(food2)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipeWithNoLogs);

            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);
            var result = logPostService.getLogsByRecipe(recipeWithNoLogs.getPublicId(), pageable, "en");

            assertThat(result.getContent()).isEmpty();
        }

        @Test
        @DisplayName("Should throw exception when recipe not found")
        void getLogsByRecipe_RecipeNotFound_ThrowsException() {
            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);

            assertThatThrownBy(() -> logPostService.getLogsByRecipe(
                    java.util.UUID.randomUUID(),
                    pageable,
                    "en"
            )).isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Recipe not found");
        }

        @Test
        @DisplayName("Should not return deleted logs")
        void getLogsByRecipe_ExcludesDeletedLogs() {
            // Soft delete the log post
            testLogPost.softDelete();
            logPostRepository.save(testLogPost);

            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);
            var result = logPostService.getLogsByRecipe(testRecipe.getPublicId(), pageable, "en");

            assertThat(result.getContent()).isEmpty();
        }

        @Test
        @DisplayName("Should paginate logs correctly")
        void getLogsByRecipe_Pagination_Works() {
            // Create more logs for pagination test
            for (int i = 0; i < 5; i++) {
                LogPost log = LogPost.builder()
                        .title("Log " + i)
                        .content("Content " + i)
                        .locale("ko-KR")
                        .creatorId(testUser.getId())
                        .build();

                RecipeLog recipeLog = RecipeLog.builder()
                        .logPost(log)
                        .recipe(testRecipe)
                        .rating(5)
                        .build();
                log.setRecipeLog(recipeLog);
                logPostRepository.save(log);
            }

            // First page (size 3)
            var page1 = org.springframework.data.domain.PageRequest.of(0, 3);
            var result1 = logPostService.getLogsByRecipe(testRecipe.getPublicId(), page1, "en");

            assertThat(result1.getContent()).hasSize(3);
            assertThat(result1.hasNext()).isTrue();

            // Second page
            var page2 = org.springframework.data.domain.PageRequest.of(1, 3);
            var result2 = logPostService.getLogsByRecipe(testRecipe.getPublicId(), page2, "en");

            assertThat(result2.getContent()).hasSize(3);
            assertThat(result2.hasNext()).isFalse();
        }

        @Test
        @DisplayName("Should return logs ordered by created date descending")
        void getLogsByRecipe_OrderedByCreatedAtDesc() {
            // Create more logs with slight delay to ensure different timestamps
            LogPost newerLog = LogPost.builder()
                    .title("Newer Log")
                    .content("Newer content")
                    .locale("ko-KR")
                    .creatorId(testUser.getId())
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(newerLog)
                    .recipe(testRecipe)
                    .rating(3)
                    .build();
            newerLog.setRecipeLog(recipeLog);
            logPostRepository.save(newerLog);

            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);
            var result = logPostService.getLogsByRecipe(testRecipe.getPublicId(), pageable, "en");

            assertThat(result.getContent()).hasSize(2);
            // Newer log should come first
            assertThat(result.getContent().get(0).title()).isEqualTo("Newer Log");
        }
    }
}
