package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.log_post.UpdateLogRequestDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
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
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class LogPostControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    private User testUser;
    private User otherUser;
    private Recipe testRecipe;
    private LogPost testLogPost;
    private String testUserToken;
    private String otherUserToken;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();
        otherUser = testUserFactory.createTestUser("other_user");

        testUserToken = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");
        otherUserToken = testJwtTokenProvider.createAccessToken(otherUser.getPublicId(), "USER");

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
    @DisplayName("GET /api/v1/log_posts/{publicId} - Log Detail")
    class GetLogDetailTests {

        @Test
        @DisplayName("Should return log detail with creatorPublicId")
        void getLogDetail_ReturnsCreatorPublicId() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + testUserToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.publicId").value(testLogPost.getPublicId().toString()))
                    .andExpect(jsonPath("$.creatorPublicId").value(testUser.getPublicId().toString()));
        }
    }

    @Nested
    @DisplayName("PUT /api/v1/log_posts/{publicId} - Update Log")
    class UpdateLogTests {

        @Test
        @DisplayName("Should update log when user is the owner")
        void updateLog_AsOwner_Returns200() throws Exception {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars
                    List.of("tag1", "tag2"),
                    null,
                    null  // isPrivate
            );

            mockMvc.perform(put("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + testUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").value("Updated content"))
                    .andExpect(jsonPath("$.rating").value(3));

            // Verify database update
            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getContent()).isEqualTo("Updated content");
        }

        @Test
        @DisplayName("Should return 403 when user is not the owner")
        void updateLog_NotOwner_Returns403() throws Exception {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars
                    null,
                    null,
                    null  // isPrivate
            );

            mockMvc.perform(put("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + otherUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Should return 401 without auth")
        void updateLog_NoAuth_Returns401() throws Exception {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars
                    null,
                    null,
                    null  // isPrivate
            );

            mockMvc.perform(put("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 400 when log not found")
        void updateLog_NotFound_Returns400() throws Exception {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars
                    null,
                    null,
                    null  // isPrivate
            );

            mockMvc.perform(put("/api/v1/log_posts/" + UUID.randomUUID())
                            .header("Authorization", "Bearer " + testUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should return 400 when content is blank")
        void updateLog_BlankContent_Returns400() throws Exception {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "",  // blank content
                    3,  // 3 stars
                    null,
                    null,
                    null  // isPrivate
            );

            mockMvc.perform(put("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + testUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should return 400 when rating is invalid (out of range)")
        void updateLog_InvalidRating_Returns400() throws Exception {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    6,  // invalid rating (max is 5)
                    null,
                    null,
                    null  // isPrivate
            );

            mockMvc.perform(put("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + testUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("DELETE /api/v1/log_posts/{publicId} - Delete Log")
    class DeleteLogTests {

        @Test
        @DisplayName("Should soft delete log when user is the owner")
        void deleteLog_AsOwner_Returns204() throws Exception {
            mockMvc.perform(delete("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + testUserToken))
                    .andExpect(status().isNoContent());

            // Verify soft delete
            LogPost deleted = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(deleted.isDeleted()).isTrue();
        }

        @Test
        @DisplayName("Should return 403 when user is not the owner")
        void deleteLog_NotOwner_Returns403() throws Exception {
            mockMvc.perform(delete("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + otherUserToken))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Should return 401 without auth")
        void deleteLog_NoAuth_Returns401() throws Exception {
            mockMvc.perform(delete("/api/v1/log_posts/" + testLogPost.getPublicId()))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 400 when log not found")
        void deleteLog_NotFound_Returns400() throws Exception {
            mockMvc.perform(delete("/api/v1/log_posts/" + UUID.randomUUID())
                            .header("Authorization", "Bearer " + testUserToken))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/log_posts/recipe/{recipePublicId} - Logs by Recipe")
    class GetLogsByRecipeTests {

        @Test
        @DisplayName("Should return logs for a specific recipe")
        void getLogsByRecipe_ReturnsLogs() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts/recipe/" + testRecipe.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content.length()").value(1))
                    .andExpect(jsonPath("$.content[0].publicId").value(testLogPost.getPublicId().toString()))
                    .andExpect(jsonPath("$.content[0].title").value("Test Log"))
                    .andExpect(jsonPath("$.content[0].rating").value(5));
        }

        @Test
        @DisplayName("Should return empty content when recipe has no logs")
        void getLogsByRecipe_NoLogs_ReturnsEmpty() throws Exception {
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

            mockMvc.perform(get("/api/v1/log_posts/recipe/" + recipeWithNoLogs.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content.length()").value(0))
                    .andExpect(jsonPath("$.last").value(true));
        }

        @Test
        @DisplayName("Should return 400 when recipe not found")
        void getLogsByRecipe_RecipeNotFound_Returns400() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts/recipe/" + UUID.randomUUID()))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should support pagination parameters")
        void getLogsByRecipe_Pagination_Works() throws Exception {
            // Create more logs
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

            // First page with size 3
            mockMvc.perform(get("/api/v1/log_posts/recipe/" + testRecipe.getPublicId())
                            .param("page", "0")
                            .param("size", "3"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content.length()").value(3))
                    .andExpect(jsonPath("$.last").value(false));

            // Second page
            mockMvc.perform(get("/api/v1/log_posts/recipe/" + testRecipe.getPublicId())
                            .param("page", "1")
                            .param("size", "3"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content.length()").value(3))
                    .andExpect(jsonPath("$.last").value(true));
        }

        @Test
        @DisplayName("Should not include deleted logs in response")
        void getLogsByRecipe_ExcludesDeletedLogs() throws Exception {
            // Soft delete the log
            testLogPost.softDelete();
            logPostRepository.save(testLogPost);

            mockMvc.perform(get("/api/v1/log_posts/recipe/" + testRecipe.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content.length()").value(0));
        }

        @Test
        @DisplayName("Should work without authentication (public endpoint)")
        void getLogsByRecipe_NoAuth_Works() throws Exception {
            // No auth header - should still work as this is a public read endpoint
            mockMvc.perform(get("/api/v1/log_posts/recipe/" + testRecipe.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should include thumbnailUrl and userName in response")
        void getLogsByRecipe_IncludesAllFields() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts/recipe/" + testRecipe.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content[0].publicId").exists())
                    .andExpect(jsonPath("$.content[0].title").exists())
                    .andExpect(jsonPath("$.content[0].rating").exists())
                    .andExpect(jsonPath("$.content[0].userName").value(testUser.getUsername()));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/log_posts - Sort Options")
    class GetLogsWithSortTests {

        @Test
        @DisplayName("Should return logs sorted by recent (default)")
        void getLogs_DefaultSort_ReturnsRecentFirst() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should accept popular sort parameter")
        void getLogs_PopularSort_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts")
                            .param("sort", "popular"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should accept trending sort parameter")
        void getLogs_TrendingSort_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts")
                            .param("sort", "trending"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should accept recent sort parameter explicitly")
        void getLogs_RecentSort_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts")
                            .param("sort", "recent"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should combine sort with rating filter")
        void getLogs_SortWithRatingFilter_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts")
                            .param("sort", "popular")
                            .param("minRating", "4"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should combine sort with pagination")
        void getLogs_SortWithPagination_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts")
                            .param("sort", "trending")
                            .param("page", "0")
                            .param("size", "10"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }
    }

    @Nested
    @DisplayName("View Count Increment")
    class ViewCountTests {

        @Test
        @DisplayName("Should increment view count when viewing log detail")
        void getLogDetail_IncrementsViewCount() throws Exception {
            Integer initialViewCount = testLogPost.getViewCount();

            mockMvc.perform(get("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + testUserToken))
                    .andExpect(status().isOk());

            // Verify view count was incremented
            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getViewCount()).isEqualTo((initialViewCount != null ? initialViewCount : 0) + 1);
        }
    }
}
