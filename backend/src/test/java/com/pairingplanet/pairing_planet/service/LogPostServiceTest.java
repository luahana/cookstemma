package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostDetailResponseDto;
import com.pairingplanet.pairing_planet.dto.log_post.UpdateLogRequestDto;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.support.BaseIntegrationTest;
import com.pairingplanet.pairing_planet.support.TestUserFactory;
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
                .culinaryLocale("ko-KR")
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
                .outcome("SUCCESS")
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
                    "PARTIAL",
                    List.of("tag1", "tag2"),
                    null
            );

            LogPostDetailResponseDto result = logPostService.updateLog(
                    testLogPost.getPublicId(),
                    request,
                    testUser.getId()
            );

            assertThat(result.content()).isEqualTo("Updated content");
            assertThat(result.outcome()).isEqualTo("PARTIAL");

            // Verify in database
            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getContent()).isEqualTo("Updated content");
            assertThat(updated.getRecipeLog().getOutcome()).isEqualTo("PARTIAL");
        }

        @Test
        @DisplayName("Should throw AccessDeniedException when user is not the owner")
        void updateLog_NotOwner_ThrowsException() {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    "PARTIAL",
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
                    "PARTIAL",
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
                    "SUCCESS",
                    List.of("tag1", "tag2"),
                    null
            );
            logPostService.updateLog(testLogPost.getPublicId(), addTagsRequest, testUser.getId());

            // Then clear them
            UpdateLogRequestDto clearTagsRequest = new UpdateLogRequestDto(
                    null,
                    "Content without tags",
                    "SUCCESS",
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
            assertThat(deleted.getIsDeleted()).isTrue();
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
}
