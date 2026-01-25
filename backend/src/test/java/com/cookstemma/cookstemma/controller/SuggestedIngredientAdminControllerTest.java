package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.ingredient.UserSuggestedIngredient;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.repository.ingredient.UserSuggestedIngredientRepository;
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

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class SuggestedIngredientAdminControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserSuggestedIngredientRepository suggestedIngredientRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    private User adminUser;
    private User regularUser;
    private String adminToken;
    private String userToken;
    private UserSuggestedIngredient testSuggestion;

    @BeforeEach
    void setUp() {
        adminUser = testUserFactory.createAdminUser();
        regularUser = testUserFactory.createTestUser();
        adminToken = testJwtTokenProvider.createAccessToken(adminUser.getPublicId(), "ADMIN");
        userToken = testJwtTokenProvider.createAccessToken(regularUser.getPublicId(), "USER");

        testSuggestion = UserSuggestedIngredient.builder()
                .suggestedName("Test Ingredient " + System.currentTimeMillis())
                .ingredientType(IngredientType.MAIN)
                .localeCode("en-US")
                .user(regularUser)
                .status(SuggestionStatus.PENDING)
                .build();
        suggestedIngredientRepository.saveAndFlush(testSuggestion);
    }

    @Nested
    @DisplayName("GET /api/v1/admin/suggested-ingredients - List Suggested Ingredients")
    class ListSuggestedIngredients {

        @Test
        @DisplayName("Admin can get all suggested ingredients")
        void getSuggestedIngredients_AsAdmin_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/suggested-ingredients")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content[0].publicId").exists())
                    .andExpect(jsonPath("$.content[0].suggestedName").exists())
                    .andExpect(jsonPath("$.content[0].ingredientType").exists());
        }

        @Test
        @DisplayName("Admin can filter by ingredient type")
        void getSuggestedIngredients_FilterByType_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/suggested-ingredients")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("ingredientType", "MAIN"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Admin can filter by status")
        void getSuggestedIngredients_FilterByStatus_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/suggested-ingredients")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("status", "PENDING"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Non-admin cannot get suggested ingredients")
        void getSuggestedIngredients_AsUser_Forbidden() throws Exception {
            mockMvc.perform(get("/api/v1/admin/suggested-ingredients")
                            .header("Authorization", "Bearer " + userToken))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Unauthenticated request returns 401")
        void getSuggestedIngredients_NoAuth_Unauthorized() throws Exception {
            mockMvc.perform(get("/api/v1/admin/suggested-ingredients"))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("PATCH /api/v1/admin/suggested-ingredients/{publicId}/status - Update Status")
    class UpdateStatus {

        @Test
        @DisplayName("Admin can approve suggested ingredient")
        void updateStatus_Approve_Success() throws Exception {
            Map<String, String> request = Map.of("status", "APPROVED");

            mockMvc.perform(patch("/api/v1/admin/suggested-ingredients/" +
                            testSuggestion.getPublicId() + "/status")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.status").value("APPROVED"))
                    .andExpect(jsonPath("$.autocompleteItemPublicId").exists());
        }

        @Test
        @DisplayName("Admin can reject suggested ingredient")
        void updateStatus_Reject_Success() throws Exception {
            Map<String, String> request = Map.of("status", "REJECTED");

            mockMvc.perform(patch("/api/v1/admin/suggested-ingredients/" +
                            testSuggestion.getPublicId() + "/status")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.status").value("REJECTED"))
                    .andExpect(jsonPath("$.autocompleteItemPublicId").doesNotExist());
        }

        @Test
        @DisplayName("Non-admin cannot update status")
        void updateStatus_AsUser_Forbidden() throws Exception {
            Map<String, String> request = Map.of("status", "APPROVED");

            mockMvc.perform(patch("/api/v1/admin/suggested-ingredients/" +
                            testSuggestion.getPublicId() + "/status")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Unauthenticated request returns 401")
        void updateStatus_NoAuth_Unauthorized() throws Exception {
            Map<String, String> request = Map.of("status", "APPROVED");

            mockMvc.perform(patch("/api/v1/admin/suggested-ingredients/" +
                            testSuggestion.getPublicId() + "/status")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Returns 400 for non-existent suggestion")
        void updateStatus_NotFound_BadRequest() throws Exception {
            Map<String, String> request = Map.of("status", "APPROVED");

            mockMvc.perform(patch("/api/v1/admin/suggested-ingredients/" +
                            java.util.UUID.randomUUID() + "/status")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }
}
