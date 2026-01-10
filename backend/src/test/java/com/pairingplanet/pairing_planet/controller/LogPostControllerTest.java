package com.pairingplanet.pairing_planet.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.log_post.UpdateLogRequestDto;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
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
                .culinaryLocale("ko-KR")
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
                .outcome("SUCCESS")
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
                    "PARTIAL",
                    List.of("tag1", "tag2"),
                    null
            );

            mockMvc.perform(put("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + testUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").value("Updated content"))
                    .andExpect(jsonPath("$.outcome").value("PARTIAL"));

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
                    "PARTIAL",
                    null,
                    null
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
                    "PARTIAL",
                    null,
                    null
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
                    "PARTIAL",
                    null,
                    null
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
                    "PARTIAL",
                    null,
                    null
            );

            mockMvc.perform(put("/api/v1/log_posts/" + testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + testUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should return 400 when outcome is invalid")
        void updateLog_InvalidOutcome_Returns400() throws Exception {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    "INVALID_OUTCOME",  // invalid outcome
                    null,
                    null
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
            assertThat(deleted.getIsDeleted()).isTrue();
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
}
