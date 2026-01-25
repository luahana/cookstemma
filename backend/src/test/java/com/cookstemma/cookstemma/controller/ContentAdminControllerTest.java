package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.comment.Comment;
import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.comment.CommentRepository;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ContentAdminControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    private User adminUser;
    private User regularUser;
    private String adminToken;
    private String userToken;
    private Recipe testRecipe;
    private LogPost testLogPost;
    private Comment testComment;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        adminUser = testUserFactory.createAdminUser();
        regularUser = testUserFactory.createTestUser();
        adminToken = testJwtTokenProvider.createAccessToken(adminUser.getPublicId(), "ADMIN");
        userToken = testJwtTokenProvider.createAccessToken(regularUser.getPublicId(), "USER");

        // Create test food
        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.saveAndFlush(testFood);

        // Create test recipe
        testRecipe = Recipe.builder()
                .title("Test Recipe " + System.currentTimeMillis())
                .description("Test description")
                .cookingStyle("ko-KR")
                .foodMaster(testFood)
                .creatorId(regularUser.getId())
                .build();
        recipeRepository.saveAndFlush(testRecipe);

        // Create test log post
        testLogPost = LogPost.builder()
                .title("Test Log Post")
                .content("Test log content " + System.currentTimeMillis())
                .locale("ko-KR")
                .creatorId(regularUser.getId())
                .commentCount(0)
                .build();
        logPostRepository.saveAndFlush(testLogPost);

        // Create test comment
        testComment = Comment.builder()
                .logPost(testLogPost)
                .creator(regularUser)
                .content("Test comment " + System.currentTimeMillis())
                .replyCount(0)
                .likeCount(0)
                .build();
        commentRepository.saveAndFlush(testComment);
    }

    // ==================== RECIPES ====================

    @Nested
    @DisplayName("GET /api/v1/admin/recipes - List All Recipes")
    class ListRecipes {

        @Test
        @DisplayName("Admin can list all recipes")
        void getRecipes_AsAdmin_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/recipes")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content[0].publicId").exists())
                    .andExpect(jsonPath("$.content[0].title").exists())
                    .andExpect(jsonPath("$.content[0].creatorUsername").exists());
        }

        @Test
        @DisplayName("Admin can filter recipes by title")
        void getRecipes_FilterByTitle_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/recipes")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("title", "Test Recipe"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Admin can filter recipes by username")
        void getRecipes_FilterByUsername_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/recipes")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("username", regularUser.getUsername().substring(0, 5)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Non-admin cannot list recipes")
        void getRecipes_AsUser_Forbidden() throws Exception {
            mockMvc.perform(get("/api/v1/admin/recipes")
                            .header("Authorization", "Bearer " + userToken))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Unauthenticated request returns 401")
        void getRecipes_NoAuth_Unauthorized() throws Exception {
            mockMvc.perform(get("/api/v1/admin/recipes"))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/admin/recipes/delete - Delete Recipes")
    class DeleteRecipes {

        @Test
        @DisplayName("Admin can delete recipes (bypasses owner check)")
        void deleteRecipes_AsAdmin_Success() throws Exception {
            Map<String, Object> request = Map.of("publicIds", List.of(testRecipe.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/recipes/delete")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.deletedCount").value(1))
                    .andExpect(jsonPath("$.message").value("Recipes deleted successfully"));

            // Verify recipe is soft-deleted
            Recipe deleted = recipeRepository.findById(testRecipe.getId()).orElseThrow();
            assertThat(deleted.getDeletedAt()).isNotNull();
        }

        @Test
        @DisplayName("Admin can delete recipe with variants (bypasses restriction)")
        void deleteRecipes_WithVariants_Success() throws Exception {
            // Create a variant
            Recipe variant = Recipe.builder()
                    .title("Variant Recipe")
                    .description("Variant description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(regularUser.getId())
                    .parentRecipe(testRecipe)
                    .rootRecipe(testRecipe)
                    .build();
            recipeRepository.saveAndFlush(variant);

            Map<String, Object> request = Map.of("publicIds", List.of(testRecipe.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/recipes/delete")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.deletedCount").value(1));
        }

        @Test
        @DisplayName("Non-admin cannot delete recipes")
        void deleteRecipes_AsUser_Forbidden() throws Exception {
            Map<String, Object> request = Map.of("publicIds", List.of(testRecipe.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/recipes/delete")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }
    }

    // ==================== LOG POSTS ====================

    @Nested
    @DisplayName("GET /api/v1/admin/logs - List All Logs")
    class ListLogs {

        @Test
        @DisplayName("Admin can list all logs")
        void getLogs_AsAdmin_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/logs")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content[0].publicId").exists())
                    .andExpect(jsonPath("$.content[0].content").exists())
                    .andExpect(jsonPath("$.content[0].creatorUsername").exists());
        }

        @Test
        @DisplayName("Admin can filter logs by content")
        void getLogs_FilterByContent_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/logs")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("content", "Test log"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Admin can filter logs by username")
        void getLogs_FilterByUsername_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/logs")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("username", regularUser.getUsername().substring(0, 5)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Non-admin cannot list logs")
        void getLogs_AsUser_Forbidden() throws Exception {
            mockMvc.perform(get("/api/v1/admin/logs")
                            .header("Authorization", "Bearer " + userToken))
                    .andExpect(status().isForbidden());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/admin/logs/delete - Delete Logs")
    class DeleteLogs {

        @Test
        @DisplayName("Admin can delete logs (bypasses owner check)")
        void deleteLogs_AsAdmin_Success() throws Exception {
            Map<String, Object> request = Map.of("publicIds", List.of(testLogPost.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/logs/delete")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.deletedCount").value(1))
                    .andExpect(jsonPath("$.message").value("Log posts deleted successfully"));

            // Verify log is soft-deleted
            LogPost deleted = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(deleted.getDeletedAt()).isNotNull();
        }

        @Test
        @DisplayName("Non-admin cannot delete logs")
        void deleteLogs_AsUser_Forbidden() throws Exception {
            Map<String, Object> request = Map.of("publicIds", List.of(testLogPost.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/logs/delete")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }
    }

    // ==================== COMMENTS ====================

    @Nested
    @DisplayName("GET /api/v1/admin/comments - List All Comments")
    class ListComments {

        @Test
        @DisplayName("Admin can list all comments")
        void getComments_AsAdmin_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/comments")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content[0].publicId").exists())
                    .andExpect(jsonPath("$.content[0].content").exists())
                    .andExpect(jsonPath("$.content[0].creatorUsername").exists());
        }

        @Test
        @DisplayName("Admin can filter comments by content")
        void getComments_FilterByContent_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/comments")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("content", "Test comment"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Admin can filter comments by username")
        void getComments_FilterByUsername_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/comments")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("username", regularUser.getUsername().substring(0, 5)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Non-admin cannot list comments")
        void getComments_AsUser_Forbidden() throws Exception {
            mockMvc.perform(get("/api/v1/admin/comments")
                            .header("Authorization", "Bearer " + userToken))
                    .andExpect(status().isForbidden());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/admin/comments/delete - Delete Comments")
    class DeleteComments {

        @Test
        @DisplayName("Admin can delete comments (bypasses owner check)")
        void deleteComments_AsAdmin_Success() throws Exception {
            Map<String, Object> request = Map.of("publicIds", List.of(testComment.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/comments/delete")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.deletedCount").value(1))
                    .andExpect(jsonPath("$.message").value("Comments deleted successfully"));

            // Verify comment is soft-deleted
            Comment deleted = commentRepository.findById(testComment.getId()).orElseThrow();
            assertThat(deleted.getDeletedAt()).isNotNull();
        }

        @Test
        @DisplayName("Deleting comment decrements log post comment count")
        void deleteComments_DecrementsCommentCount() throws Exception {
            // Set initial comment count
            testLogPost.setCommentCount(1);
            logPostRepository.saveAndFlush(testLogPost);

            Map<String, Object> request = Map.of("publicIds", List.of(testComment.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/comments/delete")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());

            // Verify comment count is decremented
            LogPost updated = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(updated.getCommentCount()).isEqualTo(0);
        }

        @Test
        @DisplayName("Deleting reply decrements parent reply count")
        void deleteComments_DecrementsReplyCount() throws Exception {
            // Create a reply
            testComment.setReplyCount(1);
            commentRepository.saveAndFlush(testComment);

            Comment reply = Comment.builder()
                    .logPost(testLogPost)
                    .creator(regularUser)
                    .parent(testComment)
                    .content("Test reply")
                    .replyCount(0)
                    .likeCount(0)
                    .build();
            commentRepository.saveAndFlush(reply);

            Map<String, Object> request = Map.of("publicIds", List.of(reply.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/comments/delete")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());

            // Verify parent reply count is decremented
            Comment parent = commentRepository.findById(testComment.getId()).orElseThrow();
            assertThat(parent.getReplyCount()).isEqualTo(0);
        }

        @Test
        @DisplayName("Non-admin cannot delete comments")
        void deleteComments_AsUser_Forbidden() throws Exception {
            Map<String, Object> request = Map.of("publicIds", List.of(testComment.getPublicId().toString()));

            mockMvc.perform(post("/api/v1/admin/comments/delete")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }
    }
}
