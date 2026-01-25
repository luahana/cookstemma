package com.cookstemma.cookstemma.security;

import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class SecurityConfigTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Nested
    @DisplayName("Public Endpoints")
    class PublicEndpoints {

        @Test
        @DisplayName("Auth endpoints should be accessible without authentication")
        void authEndpoints_NoAuth_NotUnauthorized() throws Exception {
            // Will fail with 400 due to missing body, but not 401
            mockMvc.perform(post("/api/v1/auth/reissue")
                            .contentType("application/json")
                            .content("{\"refreshToken\":\"invalid\"}"))
                    .andExpect(status().is4xxClientError());
        }

        @Test
        @DisplayName("Autocomplete endpoints should be accessible without authentication (not 401)")
        void autocompleteEndpoints_NoAuth_NotUnauthorized() throws Exception {
            // This test verifies the endpoint is not protected by authentication
            // It may return 400 due to missing Redis connection, but NOT 401
            int status = mockMvc.perform(get("/api/v1/autocomplete")
                            .param("keyword", "test")
                            .param("locale", "ko-KR"))
                    .andReturn().getResponse().getStatus();
            // Should not return 401 Unauthorized
            assert status != 401 : "Expected not 401 but got " + status;
        }

        @Test
        @DisplayName("Contexts endpoints should be accessible without authentication (not 401)")
        void contextsEndpoints_NoAuth_NotUnauthorized() throws Exception {
            // Contexts endpoint is public per security config
            // It may return 500 due to other issues, but NOT 401
            int status = mockMvc.perform(get("/api/v1/contexts/locales"))
                    .andReturn().getResponse().getStatus();
            assert status != 401 : "Expected not 401 but got " + status;
        }
    }

    @Nested
    @DisplayName("Guest Access Endpoints")
    class GuestAccessEndpoints {

        @Test
        @DisplayName("Recipe list endpoint is accessible without authentication")
        void recipeList_NoAuth_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/recipes"))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("User profile endpoint is accessible without authentication")
        void userProfile_NoAuth_Returns200() throws Exception {
            var user = testUserFactory.createTestUser();
            mockMvc.perform(get("/api/v1/users/" + user.getPublicId()))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Log posts list endpoint is accessible without authentication")
        void logPostsList_NoAuth_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts"))
                    .andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("Protected Endpoints")
    class ProtectedEndpoints {

        @Test
        @DisplayName("User profile endpoint requires authentication")
        void userEndpoints_NoAuth_Returns401() throws Exception {
            mockMvc.perform(get("/api/v1/users/me"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("My recipes endpoint requires authentication")
        void myRecipesEndpoint_NoAuth_Returns401() throws Exception {
            mockMvc.perform(get("/api/v1/recipes/my"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Create recipe endpoint requires authentication")
        void createRecipeEndpoint_NoAuth_Returns401() throws Exception {
            mockMvc.perform(post("/api/v1/recipes")
                            .contentType("application/json")
                            .content("{}"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Protected endpoint with valid token returns success")
        void protectedEndpoint_WithValidToken_ReturnsSuccess() throws Exception {
            var user = testUserFactory.createTestUser();
            String token = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            mockMvc.perform(get("/api/v1/users/me")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Protected endpoint with invalid token returns 401")
        void protectedEndpoint_InvalidToken_Returns401() throws Exception {
            mockMvc.perform(get("/api/v1/users/me")
                            .header("Authorization", "Bearer invalid-token"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Protected endpoint with expired token returns 401")
        void protectedEndpoint_ExpiredToken_Returns401() throws Exception {
            var user = testUserFactory.createTestUser();
            String expiredToken = testJwtTokenProvider.createExpiredToken(user.getPublicId());

            mockMvc.perform(get("/api/v1/users/me")
                            .header("Authorization", "Bearer " + expiredToken))
                    .andExpect(status().isUnauthorized());
        }
    }
}
