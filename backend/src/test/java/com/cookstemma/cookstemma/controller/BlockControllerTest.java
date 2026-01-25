package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.service.BlockService;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class BlockControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private BlockService blockService;

    private User user1;
    private User user2;
    private String user1Token;
    private String user2Token;

    @BeforeEach
    void setUp() {
        user1 = testUserFactory.createTestUser("blocker_" + System.currentTimeMillis());
        user2 = testUserFactory.createTestUser("blocked_" + System.currentTimeMillis());
        user1Token = testJwtTokenProvider.createAccessToken(user1.getPublicId(), "USER");
        user2Token = testJwtTokenProvider.createAccessToken(user2.getPublicId(), "USER");
    }

    @Nested
    @DisplayName("POST /api/v1/users/{userId}/block - Block User")
    class BlockUser {

        @Test
        @DisplayName("Should block user with valid token")
        void blockUser_ValidToken_Returns200() throws Exception {
            mockMvc.perform(post("/api/v1/users/{userId}/block", user2.getPublicId())
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Should return 401 without token")
        void blockUser_NoToken_Returns401() throws Exception {
            mockMvc.perform(post("/api/v1/users/{userId}/block", user2.getPublicId()))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 401 for non-existent user")
        void blockUser_NonExistentUser_Returns401() throws Exception {
            // "User not found" exception is mapped to 401 by GlobalExceptionHandler
            mockMvc.perform(post("/api/v1/users/{userId}/block", UUID.randomUUID())
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should handle blocking already-blocked user gracefully")
        void blockUser_AlreadyBlocked_Returns200() throws Exception {
            // Block first time
            blockService.blockUser(user1.getId(), user2.getPublicId());

            // Block again should still return 200
            mockMvc.perform(post("/api/v1/users/{userId}/block", user2.getPublicId())
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("DELETE /api/v1/users/{userId}/block - Unblock User")
    class UnblockUser {

        @Test
        @DisplayName("Should unblock user with valid token")
        void unblockUser_ValidToken_Returns200() throws Exception {
            // Setup: block first
            blockService.blockUser(user1.getId(), user2.getPublicId());

            mockMvc.perform(delete("/api/v1/users/{userId}/block", user2.getPublicId())
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Should return 401 without token")
        void unblockUser_NoToken_Returns401() throws Exception {
            mockMvc.perform(delete("/api/v1/users/{userId}/block", user2.getPublicId()))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should handle unblocking non-blocked user gracefully")
        void unblockUser_NotBlocked_Returns200() throws Exception {
            mockMvc.perform(delete("/api/v1/users/{userId}/block", user2.getPublicId())
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/users/{userId}/block-status - Get Block Status")
    class GetBlockStatus {

        @Test
        @DisplayName("Should return isBlocked=true when blocked")
        void getBlockStatus_Blocked_ReturnsIsBlockedTrue() throws Exception {
            blockService.blockUser(user1.getId(), user2.getPublicId());

            mockMvc.perform(get("/api/v1/users/{userId}/block-status", user2.getPublicId())
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.isBlocked").value(true))
                    .andExpect(jsonPath("$.amBlocked").value(false));
        }

        @Test
        @DisplayName("Should return amBlocked=true when blocked by target")
        void getBlockStatus_AmBlocked_ReturnsAmBlockedTrue() throws Exception {
            blockService.blockUser(user2.getId(), user1.getPublicId()); // user2 blocks user1

            mockMvc.perform(get("/api/v1/users/{userId}/block-status", user2.getPublicId())
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.isBlocked").value(false))
                    .andExpect(jsonPath("$.amBlocked").value(true));
        }

        @Test
        @DisplayName("Should return both false when no block")
        void getBlockStatus_NoBlock_ReturnsBothFalse() throws Exception {
            mockMvc.perform(get("/api/v1/users/{userId}/block-status", user2.getPublicId())
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.isBlocked").value(false))
                    .andExpect(jsonPath("$.amBlocked").value(false));
        }

        @Test
        @DisplayName("Should return both false without token (guest mode)")
        void getBlockStatus_NoToken_ReturnsBothFalse() throws Exception {
            // GET is permitAll for /users/**, principal is null, returns false/false
            mockMvc.perform(get("/api/v1/users/{userId}/block-status", user2.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.isBlocked").value(false))
                    .andExpect(jsonPath("$.amBlocked").value(false));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/users/me/blocked - Get Blocked Users List")
    class GetBlockedUsers {

        @Test
        @DisplayName("Should return blocked users list")
        void getBlockedUsers_HasBlocked_ReturnsList() throws Exception {
            blockService.blockUser(user1.getId(), user2.getPublicId());

            mockMvc.perform(get("/api/v1/users/me/blocked")
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content.length()").value(1))
                    .andExpect(jsonPath("$.content[0].publicId").value(user2.getPublicId().toString()))
                    .andExpect(jsonPath("$.content[0].username").value(user2.getUsername()));
        }

        @Test
        @DisplayName("Should return empty list when no blocked users")
        void getBlockedUsers_NoBlocked_ReturnsEmptyList() throws Exception {
            mockMvc.perform(get("/api/v1/users/me/blocked")
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content.length()").value(0));
        }

        @Test
        @DisplayName("Should support pagination")
        void getBlockedUsers_Pagination_ReturnsCorrectPage() throws Exception {
            mockMvc.perform(get("/api/v1/users/me/blocked")
                            .param("page", "0")
                            .param("size", "10")
                            .header("Authorization", "Bearer " + user1Token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.page").value(0))
                    .andExpect(jsonPath("$.size").value(10));
        }

        @Test
        @DisplayName("Should return 401 without token")
        void getBlockedUsers_NoToken_Returns401() throws Exception {
            mockMvc.perform(get("/api/v1/users/me/blocked"))
                    .andExpect(status().isUnauthorized());
        }
    }
}
