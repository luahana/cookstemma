package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class UserControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Nested
    @DisplayName("GET /api/v1/users/me - My Profile")
    class GetMyProfile {

        @Test
        @DisplayName("Should return my profile with valid token")
        void getMyProfile_ValidToken_ReturnsProfile() throws Exception {
            User user = testUserFactory.createTestUser();
            String token = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            mockMvc.perform(get("/api/v1/users/me")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.user.username").value(user.getUsername()))
                    .andExpect(jsonPath("$.user.id").value(user.getPublicId().toString()))
                    .andExpect(jsonPath("$.recipeCount").isNumber())
                    .andExpect(jsonPath("$.logCount").isNumber())
                    .andExpect(jsonPath("$.savedCount").isNumber());
        }

        @Test
        @DisplayName("Should return 401 without token")
        void getMyProfile_NoToken_Returns401() throws Exception {
            mockMvc.perform(get("/api/v1/users/me"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 401 with invalid token")
        void getMyProfile_InvalidToken_Returns401() throws Exception {
            mockMvc.perform(get("/api/v1/users/me")
                            .header("Authorization", "Bearer invalid-token"))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("PATCH /api/v1/users/me - Update Profile")
    class UpdateMyProfile {

        @Test
        @DisplayName("Should update profile with valid request")
        void updateMyProfile_ValidRequest_ReturnsUpdatedProfile() throws Exception {
            User user = testUserFactory.createTestUser();
            String token = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            String requestBody = "{\"username\":\"updateduser\"}";

            mockMvc.perform(patch("/api/v1/users/me")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(requestBody))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.id").exists())
                    .andExpect(jsonPath("$.username").exists());
        }

        @Test
        @DisplayName("Should return 401 without token")
        void updateMyProfile_NoToken_Returns401() throws Exception {
            mockMvc.perform(patch("/api/v1/users/me")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should update defaultCookingStyle via API")
        void updateMyProfile_WithDefaultFoodStyle_ReturnsUpdatedProfile() throws Exception {
            User user = testUserFactory.createTestUser();
            String token = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            String requestBody = "{\"defaultCookingStyle\":\"KR\"}";

            mockMvc.perform(patch("/api/v1/users/me")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(requestBody))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.defaultCookingStyle").value("KR"));
        }

        @Test
        @DisplayName("Should accept ISO country codes like US, JP")
        void updateMyProfile_ValidCountryCodes_Success() throws Exception {
            User user = testUserFactory.createTestUser();
            String token = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            String requestBody = "{\"defaultCookingStyle\":\"JP\"}";

            mockMvc.perform(patch("/api/v1/users/me")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(requestBody))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.defaultCookingStyle").value("JP"));
        }

        @Test
        @DisplayName("Should accept 'other' as valid food style")
        void updateMyProfile_OtherFoodStyle_Success() throws Exception {
            User user = testUserFactory.createTestUser();
            String token = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            String requestBody = "{\"defaultCookingStyle\":\"other\"}";

            mockMvc.perform(patch("/api/v1/users/me")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(requestBody))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.defaultCookingStyle").value("other"));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/users/{userId} - Other User Profile")
    class GetOtherUserProfile {

        @Test
        @DisplayName("Should return other user profile with valid userId")
        void getOtherUserProfile_ValidId_ReturnsProfile() throws Exception {
            User user = testUserFactory.createTestUser();
            User viewer = testUserFactory.createTestUser();
            String token = testJwtTokenProvider.createAccessToken(viewer.getPublicId(), "USER");

            mockMvc.perform(get("/api/v1/users/" + user.getPublicId())
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.username").value(user.getUsername()));
        }

        @Test
        @DisplayName("Should return level field as integer in response")
        void getOtherUserProfile_IncludesLevelAsInteger() throws Exception {
            User user = testUserFactory.createTestUser();

            mockMvc.perform(get("/api/v1/users/" + user.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.level").isNumber())
                    .andExpect(jsonPath("$.level").value(1)); // New user starts at level 1
        }

        @Test
        @DisplayName("Should return levelName field as string in response")
        void getOtherUserProfile_IncludesLevelNameAsString() throws Exception {
            User user = testUserFactory.createTestUser();

            mockMvc.perform(get("/api/v1/users/" + user.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.levelName").isString())
                    .andExpect(jsonPath("$.levelName").value("beginner")); // New user is beginner
        }

        @Test
        @DisplayName("Should return error for non-existent user")
        void getOtherUserProfile_InvalidId_ReturnsError() throws Exception {
            User viewer = testUserFactory.createTestUser();
            String token = testJwtTokenProvider.createAccessToken(viewer.getPublicId(), "USER");

            // The API returns 401 with "User not found" message for non-existent users
            mockMvc.perform(get("/api/v1/users/550e8400-e29b-41d4-a716-446655440000")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().is4xxClientError());
        }

        @Test
        @DisplayName("Should return profile without token (guest access)")
        void getOtherUserProfile_NoToken_ReturnsProfile() throws Exception {
            User user = testUserFactory.createTestUser();

            // Guest users can view other user profiles
            mockMvc.perform(get("/api/v1/users/" + user.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.username").value(user.getUsername()));
        }
    }
}
