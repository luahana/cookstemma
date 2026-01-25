package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import jakarta.servlet.http.Cookie;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for WebAuthController.
 * Tests cookie-based authentication endpoints for web clients.
 */
class WebAuthControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private UserRepository userRepository;

    @Nested
    @DisplayName("GET /api/v1/auth/web/csrf-token - CSRF Token")
    class CsrfTokenEndpoint {

        @Test
        @DisplayName("Should return CSRF token in cookie")
        void csrfToken_ReturnsTokenInCookie() throws Exception {
            MvcResult result = mockMvc.perform(get("/api/v1/auth/web/csrf-token"))
                    .andExpect(status().isOk())
                    .andReturn();

            // Check Set-Cookie header contains csrf_token
            String setCookie = result.getResponse().getHeader(HttpHeaders.SET_COOKIE);
            assertThat(setCookie).isNotNull();
            assertThat(setCookie).contains("csrf_token=");
        }

        @Test
        @DisplayName("CSRF cookie should not be HttpOnly (JS needs to read it)")
        void csrfToken_ShouldNotBeHttpOnly() throws Exception {
            MvcResult result = mockMvc.perform(get("/api/v1/auth/web/csrf-token"))
                    .andExpect(status().isOk())
                    .andReturn();

            String setCookie = result.getResponse().getHeader(HttpHeaders.SET_COOKIE);
            // HttpOnly should NOT be present in the CSRF cookie
            assertThat(setCookie).doesNotContain("HttpOnly");
        }

        @Test
        @DisplayName("CSRF cookie should have SameSite=Lax")
        void csrfToken_ShouldHaveSameSiteLax() throws Exception {
            MvcResult result = mockMvc.perform(get("/api/v1/auth/web/csrf-token"))
                    .andExpect(status().isOk())
                    .andReturn();

            String setCookie = result.getResponse().getHeader(HttpHeaders.SET_COOKIE);
            assertThat(setCookie).contains("SameSite=Lax");
        }
    }

    @Nested
    @DisplayName("POST /api/v1/auth/web/reissue - Token Reissue")
    class WebTokenReissue {

        @Test
        @DisplayName("Should reissue tokens using refresh_token cookie")
        void reissue_WithValidCookie_ReturnsNewTokens() throws Exception {
            User user = testUserFactory.createTestUser();
            String refreshToken = testJwtTokenProvider.createRefreshToken(user.getPublicId());

            // Set refresh token on user
            user.setAppRefreshToken(refreshToken);
            userRepository.save(user);

            // Get CSRF token first
            MvcResult csrfResult = mockMvc.perform(get("/api/v1/auth/web/csrf-token"))
                    .andExpect(status().isOk())
                    .andReturn();
            String csrfSetCookie = csrfResult.getResponse().getHeader(HttpHeaders.SET_COOKIE);
            String csrfToken = extractCookieValue(csrfSetCookie, "csrf_token");

            MvcResult result = mockMvc.perform(post("/api/v1/auth/web/reissue")
                            .cookie(new Cookie("refresh_token", refreshToken))
                            .cookie(new Cookie("csrf_token", csrfToken))
                            .cookie(new Cookie("access_token", "dummy-token"))
                            .header("X-CSRF-Token", csrfToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.userPublicId").value(user.getPublicId().toString()))
                    .andExpect(jsonPath("$.username").value(user.getUsername()))
                    .andReturn();

            // Verify tokens are set in cookies
            String setCookie = result.getResponse().getHeader(HttpHeaders.SET_COOKIE);
            assertThat(setCookie).contains("access_token=");
        }

        @Test
        @DisplayName("Should return 401 when no refresh_token cookie")
        void reissue_WithoutCookie_Returns401() throws Exception {
            mockMvc.perform(post("/api/v1/auth/web/reissue"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 401 when refresh_token is invalid")
        void reissue_WithInvalidCookie_Returns401() throws Exception {
            mockMvc.perform(post("/api/v1/auth/web/reissue")
                            .cookie(new Cookie("refresh_token", "invalid-token")))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 401 when refresh_token is expired")
        void reissue_WithExpiredCookie_Returns401() throws Exception {
            User user = testUserFactory.createTestUser();
            String expiredToken = testJwtTokenProvider.createExpiredToken(user.getPublicId());

            mockMvc.perform(post("/api/v1/auth/web/reissue")
                            .cookie(new Cookie("refresh_token", expiredToken)))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should clear cookies on reissue failure")
        void reissue_OnFailure_ClearsCookies() throws Exception {
            MvcResult result = mockMvc.perform(post("/api/v1/auth/web/reissue")
                            .cookie(new Cookie("refresh_token", "invalid-token")))
                    .andExpect(status().isUnauthorized())
                    .andReturn();

            // Check that clear cookies are set
            for (String setCookie : result.getResponse().getHeaders(HttpHeaders.SET_COOKIE)) {
                if (setCookie.contains("access_token=") || setCookie.contains("refresh_token=")) {
                    assertThat(setCookie).contains("Max-Age=0");
                }
            }
        }
    }

    @Nested
    @DisplayName("POST /api/v1/auth/web/logout - Logout")
    class WebLogout {

        @Test
        @DisplayName("Should return 200 and clear cookies")
        void logout_ClearsCookies() throws Exception {
            MvcResult result = mockMvc.perform(post("/api/v1/auth/web/logout"))
                    .andExpect(status().isOk())
                    .andReturn();

            // Verify cookies are cleared
            for (String setCookie : result.getResponse().getHeaders(HttpHeaders.SET_COOKIE)) {
                if (setCookie.contains("access_token=") ||
                        setCookie.contains("refresh_token=") ||
                        setCookie.contains("csrf_token=")) {
                    // Should have Max-Age=0 to clear
                    assertThat(setCookie).contains("Max-Age=0");
                }
            }
        }

        @Test
        @DisplayName("Should work without any cookies")
        void logout_WithoutCookies_ReturnsOk() throws Exception {
            mockMvc.perform(post("/api/v1/auth/web/logout"))
                    .andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("Cookie Security Attributes")
    class CookieSecurityTests {

        @Test
        @DisplayName("Access token cookie should be HttpOnly")
        void accessTokenCookie_ShouldBeHttpOnly() throws Exception {
            User user = testUserFactory.createTestUser();
            String refreshToken = testJwtTokenProvider.createRefreshToken(user.getPublicId());
            user.setAppRefreshToken(refreshToken);
            userRepository.save(user);

            // Get CSRF token
            MvcResult csrfResult = mockMvc.perform(get("/api/v1/auth/web/csrf-token"))
                    .andExpect(status().isOk())
                    .andReturn();
            String csrfSetCookie = csrfResult.getResponse().getHeader(HttpHeaders.SET_COOKIE);
            String csrfToken = extractCookieValue(csrfSetCookie, "csrf_token");

            MvcResult result = mockMvc.perform(post("/api/v1/auth/web/reissue")
                            .cookie(new Cookie("refresh_token", refreshToken))
                            .cookie(new Cookie("csrf_token", csrfToken))
                            .cookie(new Cookie("access_token", "dummy"))
                            .header("X-CSRF-Token", csrfToken))
                    .andExpect(status().isOk())
                    .andReturn();

            for (String setCookie : result.getResponse().getHeaders(HttpHeaders.SET_COOKIE)) {
                if (setCookie.startsWith("access_token=") && !setCookie.contains("Max-Age=0")) {
                    assertThat(setCookie)
                            .as("Access token must be HttpOnly to prevent XSS")
                            .contains("HttpOnly");
                }
            }
        }

        @Test
        @DisplayName("Refresh token cookie should have restricted path")
        void refreshTokenCookie_ShouldHaveRestrictedPath() throws Exception {
            User user = testUserFactory.createTestUser();
            String refreshToken = testJwtTokenProvider.createRefreshToken(user.getPublicId());
            user.setAppRefreshToken(refreshToken);
            userRepository.save(user);

            // Get CSRF token
            MvcResult csrfResult = mockMvc.perform(get("/api/v1/auth/web/csrf-token"))
                    .andExpect(status().isOk())
                    .andReturn();
            String csrfSetCookie = csrfResult.getResponse().getHeader(HttpHeaders.SET_COOKIE);
            String csrfToken = extractCookieValue(csrfSetCookie, "csrf_token");

            MvcResult result = mockMvc.perform(post("/api/v1/auth/web/reissue")
                            .cookie(new Cookie("refresh_token", refreshToken))
                            .cookie(new Cookie("csrf_token", csrfToken))
                            .cookie(new Cookie("access_token", "dummy"))
                            .header("X-CSRF-Token", csrfToken))
                    .andExpect(status().isOk())
                    .andReturn();

            for (String setCookie : result.getResponse().getHeaders(HttpHeaders.SET_COOKIE)) {
                if (setCookie.startsWith("refresh_token=") && !setCookie.contains("Max-Age=0")) {
                    assertThat(setCookie)
                            .as("Refresh token should only be sent to auth endpoints")
                            .contains("Path=/api/v1/auth");
                }
            }
        }
    }

    @Nested
    @DisplayName("CSRF Protection")
    class CsrfProtectionTests {

        @Test
        @DisplayName("POST without CSRF token should fail when using cookie auth")
        void post_WithoutCsrfToken_WhenUsingCookieAuth_ShouldFail() throws Exception {
            User user = testUserFactory.createTestUser();
            String accessToken = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            // Using cookie auth without CSRF token
            mockMvc.perform(post("/api/v1/auth/web/logout")
                            .cookie(new Cookie("access_token", accessToken)))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("POST with mismatched CSRF token should fail")
        void post_WithMismatchedCsrfToken_ShouldFail() throws Exception {
            User user = testUserFactory.createTestUser();
            String accessToken = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            mockMvc.perform(post("/api/v1/auth/web/logout")
                            .cookie(new Cookie("access_token", accessToken))
                            .cookie(new Cookie("csrf_token", "correct-token"))
                            .header("X-CSRF-Token", "wrong-token"))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("POST with valid CSRF token should succeed")
        void post_WithValidCsrfToken_ShouldSucceed() throws Exception {
            String csrfToken = "valid-csrf-token-123";

            mockMvc.perform(post("/api/v1/auth/web/logout")
                            .cookie(new Cookie("access_token", "some-token"))
                            .cookie(new Cookie("csrf_token", csrfToken))
                            .header("X-CSRF-Token", csrfToken))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Mobile clients with Authorization header should bypass CSRF")
        void mobileClients_WithAuthorizationHeader_ShouldBypassCsrf() throws Exception {
            User user = testUserFactory.createTestUser();
            String accessToken = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");

            // Mobile client using Authorization header (no CSRF needed)
            mockMvc.perform(get("/api/v1/users/me")
                            .header("Authorization", "Bearer " + accessToken))
                    .andExpect(status().isOk());
        }
    }

    /**
     * Helper method to extract cookie value from Set-Cookie header
     */
    private String extractCookieValue(String setCookieHeader, String cookieName) {
        if (setCookieHeader == null) return null;

        for (String cookie : setCookieHeader.split(";")) {
            cookie = cookie.trim();
            if (cookie.startsWith(cookieName + "=")) {
                return cookie.substring(cookieName.length() + 1);
            }
        }
        return null;
    }
}
