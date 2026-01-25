package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.auth.TokenReissueRequestDto;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private UserRepository userRepository;

    @Nested
    @DisplayName("POST /api/v1/auth/reissue - Token Reissue")
    class TokenReissue {

        @Test
        @DisplayName("Valid refresh token should return new token pair")
        void reissue_ValidToken_ReturnsNewTokens() throws Exception {
            User user = testUserFactory.createTestUser();
            String refreshToken = testJwtTokenProvider.createRefreshToken(user.getPublicId());

            // Set refresh token on user (simulating previous login)
            user.setAppRefreshToken(refreshToken);
            userRepository.save(user);

            TokenReissueRequestDto request = new TokenReissueRequestDto(refreshToken);

            mockMvc.perform(post("/api/v1/auth/reissue")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.accessToken").exists())
                    .andExpect(jsonPath("$.refreshToken").exists())
                    .andExpect(jsonPath("$.userPublicId").value(user.getPublicId().toString()));
        }

        @Test
        @DisplayName("Invalid refresh token should return 401")
        void reissue_InvalidToken_Returns401() throws Exception {
            TokenReissueRequestDto request = new TokenReissueRequestDto("invalid-token");

            mockMvc.perform(post("/api/v1/auth/reissue")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Expired refresh token should return 401")
        void reissue_ExpiredToken_Returns401() throws Exception {
            User user = testUserFactory.createTestUser();
            String expiredToken = testJwtTokenProvider.createExpiredToken(user.getPublicId());

            TokenReissueRequestDto request = new TokenReissueRequestDto(expiredToken);

            mockMvc.perform(post("/api/v1/auth/reissue")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }

    }
}
