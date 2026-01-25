package com.cookstemma.cookstemma.config;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseCookie;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for CookieConfig.
 * Verifies that authentication cookies are created with proper security attributes.
 */
class CookieConfigTest {

    private CookieConfig cookieConfig;

    @Nested
    @DisplayName("Access Token Cookie")
    class AccessTokenCookieTests {

        @BeforeEach
        void setUp() {
            cookieConfig = new CookieConfig();
            ReflectionTestUtils.setField(cookieConfig, "secureCookie", true);
            ReflectionTestUtils.setField(cookieConfig, "cookieDomain", "");
        }

        @Test
        @DisplayName("Should create HttpOnly access token cookie")
        void shouldCreateHttpOnlyAccessTokenCookie() {
            // Act
            ResponseCookie cookie = cookieConfig.createAccessTokenCookie("test-access-token");

            // Assert
            assertThat(cookie.getName()).isEqualTo("access_token");
            assertThat(cookie.getValue()).isEqualTo("test-access-token");
            assertThat(cookie.isHttpOnly()).isTrue();
        }

        @Test
        @DisplayName("Should set Secure flag based on configuration")
        void shouldSetSecureFlag_BasedOnConfiguration() {
            // Act
            ResponseCookie cookie = cookieConfig.createAccessTokenCookie("test-token");

            // Assert
            assertThat(cookie.isSecure()).isTrue();
        }

        @Test
        @DisplayName("Should set SameSite to Lax for access token")
        void shouldSetSameSiteToLax_ForAccessToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createAccessTokenCookie("test-token");

            // Assert
            assertThat(cookie.getSameSite()).isEqualTo("Lax");
        }

        @Test
        @DisplayName("Should set path to root for access token")
        void shouldSetPathToRoot_ForAccessToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createAccessTokenCookie("test-token");

            // Assert
            assertThat(cookie.getPath()).isEqualTo("/");
        }

        @Test
        @DisplayName("Should set maxAge to 30 minutes for access token")
        void shouldSetMaxAgeTo30Minutes_ForAccessToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createAccessTokenCookie("test-token");

            // Assert
            assertThat(cookie.getMaxAge()).isEqualTo(Duration.ofMinutes(30));
        }

        @Test
        @DisplayName("Should not set Secure flag in development mode")
        void shouldNotSetSecureFlag_InDevelopmentMode() {
            // Arrange
            ReflectionTestUtils.setField(cookieConfig, "secureCookie", false);

            // Act
            ResponseCookie cookie = cookieConfig.createAccessTokenCookie("test-token");

            // Assert
            assertThat(cookie.isSecure()).isFalse();
        }

        @Test
        @DisplayName("Should set domain when configured")
        void shouldSetDomain_WhenConfigured() {
            // Arrange
            ReflectionTestUtils.setField(cookieConfig, "cookieDomain", ".cookstemma.com");

            // Act
            ResponseCookie cookie = cookieConfig.createAccessTokenCookie("test-token");

            // Assert
            assertThat(cookie.getDomain()).isEqualTo(".cookstemma.com");
        }
    }

    @Nested
    @DisplayName("Refresh Token Cookie")
    class RefreshTokenCookieTests {

        @BeforeEach
        void setUp() {
            cookieConfig = new CookieConfig();
            ReflectionTestUtils.setField(cookieConfig, "secureCookie", true);
            ReflectionTestUtils.setField(cookieConfig, "cookieDomain", "");
        }

        @Test
        @DisplayName("Should create HttpOnly refresh token cookie")
        void shouldCreateHttpOnlyRefreshTokenCookie() {
            // Act
            ResponseCookie cookie = cookieConfig.createRefreshTokenCookie("test-refresh-token");

            // Assert
            assertThat(cookie.getName()).isEqualTo("refresh_token");
            assertThat(cookie.getValue()).isEqualTo("test-refresh-token");
            assertThat(cookie.isHttpOnly()).isTrue();
        }

        @Test
        @DisplayName("Should set SameSite to Strict for refresh token")
        void shouldSetSameSiteToStrict_ForRefreshToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createRefreshTokenCookie("test-token");

            // Assert
            assertThat(cookie.getSameSite()).isEqualTo("Strict");
        }

        @Test
        @DisplayName("Should set path to /api/v1/auth for refresh token")
        void shouldSetPathToAuthEndpoint_ForRefreshToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createRefreshTokenCookie("test-token");

            // Assert
            assertThat(cookie.getPath()).isEqualTo("/api/v1/auth");
        }

        @Test
        @DisplayName("Should set maxAge to 14 days for refresh token")
        void shouldSetMaxAgeTo14Days_ForRefreshToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createRefreshTokenCookie("test-token");

            // Assert
            assertThat(cookie.getMaxAge()).isEqualTo(Duration.ofDays(14));
        }
    }

    @Nested
    @DisplayName("CSRF Token Cookie")
    class CsrfTokenCookieTests {

        @BeforeEach
        void setUp() {
            cookieConfig = new CookieConfig();
            ReflectionTestUtils.setField(cookieConfig, "secureCookie", true);
            ReflectionTestUtils.setField(cookieConfig, "cookieDomain", "");
        }

        @Test
        @DisplayName("Should create non-HttpOnly CSRF token cookie")
        void shouldCreateNonHttpOnlyCsrfTokenCookie() {
            // Act
            ResponseCookie cookie = cookieConfig.createCsrfTokenCookie("test-csrf-token");

            // Assert
            assertThat(cookie.getName()).isEqualTo("csrf_token");
            assertThat(cookie.getValue()).isEqualTo("test-csrf-token");
            assertThat(cookie.isHttpOnly()).isFalse(); // JS needs to read this
        }

        @Test
        @DisplayName("Should set SameSite to Lax for CSRF token")
        void shouldSetSameSiteToLax_ForCsrfToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createCsrfTokenCookie("test-token");

            // Assert
            assertThat(cookie.getSameSite()).isEqualTo("Lax");
        }

        @Test
        @DisplayName("Should set path to root for CSRF token")
        void shouldSetPathToRoot_ForCsrfToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createCsrfTokenCookie("test-token");

            // Assert
            assertThat(cookie.getPath()).isEqualTo("/");
        }

        @Test
        @DisplayName("Should set maxAge to 24 hours for CSRF token")
        void shouldSetMaxAgeTo24Hours_ForCsrfToken() {
            // Act
            ResponseCookie cookie = cookieConfig.createCsrfTokenCookie("test-token");

            // Assert
            assertThat(cookie.getMaxAge()).isEqualTo(Duration.ofHours(24));
        }
    }

    @Nested
    @DisplayName("Clear Cookie")
    class ClearCookieTests {

        @BeforeEach
        void setUp() {
            cookieConfig = new CookieConfig();
            ReflectionTestUtils.setField(cookieConfig, "secureCookie", true);
            ReflectionTestUtils.setField(cookieConfig, "cookieDomain", "");
        }

        @Test
        @DisplayName("Should create cookie with empty value")
        void shouldCreateCookie_WithEmptyValue() {
            // Act
            ResponseCookie cookie = cookieConfig.createClearCookie("access_token", "/");

            // Assert
            assertThat(cookie.getName()).isEqualTo("access_token");
            assertThat(cookie.getValue()).isEqualTo("");
        }

        @Test
        @DisplayName("Should create cookie with maxAge of 0")
        void shouldCreateCookie_WithMaxAgeZero() {
            // Act
            ResponseCookie cookie = cookieConfig.createClearCookie("access_token", "/");

            // Assert
            assertThat(cookie.getMaxAge().isZero()).isTrue();
        }

        @Test
        @DisplayName("Should use specified path")
        void shouldUseSpecifiedPath() {
            // Act
            ResponseCookie cookie = cookieConfig.createClearCookie("refresh_token", "/api/v1/auth");

            // Assert
            assertThat(cookie.getPath()).isEqualTo("/api/v1/auth");
        }
    }

    @Nested
    @DisplayName("Clear All Auth Cookies")
    class ClearAllAuthCookiesTests {

        @BeforeEach
        void setUp() {
            cookieConfig = new CookieConfig();
            ReflectionTestUtils.setField(cookieConfig, "secureCookie", true);
            ReflectionTestUtils.setField(cookieConfig, "cookieDomain", "");
        }

        @Test
        @DisplayName("Should create three clear cookies")
        void shouldCreateThreeClearCookies() {
            // Act
            ResponseCookie[] cookies = cookieConfig.createClearAuthCookies();

            // Assert
            assertThat(cookies).hasSize(3);
        }

        @Test
        @DisplayName("Should include access_token clear cookie")
        void shouldIncludeAccessTokenClearCookie() {
            // Act
            ResponseCookie[] cookies = cookieConfig.createClearAuthCookies();

            // Assert
            boolean hasAccessToken = false;
            for (ResponseCookie cookie : cookies) {
                if ("access_token".equals(cookie.getName())) {
                    hasAccessToken = true;
                    assertThat(cookie.getValue()).isEmpty();
                    assertThat(cookie.getMaxAge().isZero()).isTrue();
                    assertThat(cookie.getPath()).isEqualTo("/");
                }
            }
            assertThat(hasAccessToken).isTrue();
        }

        @Test
        @DisplayName("Should include refresh_token clear cookie")
        void shouldIncludeRefreshTokenClearCookie() {
            // Act
            ResponseCookie[] cookies = cookieConfig.createClearAuthCookies();

            // Assert
            boolean hasRefreshToken = false;
            for (ResponseCookie cookie : cookies) {
                if ("refresh_token".equals(cookie.getName())) {
                    hasRefreshToken = true;
                    assertThat(cookie.getValue()).isEmpty();
                    assertThat(cookie.getMaxAge().isZero()).isTrue();
                    assertThat(cookie.getPath()).isEqualTo("/api/v1/auth");
                }
            }
            assertThat(hasRefreshToken).isTrue();
        }

        @Test
        @DisplayName("Should include csrf_token clear cookie")
        void shouldIncludeCsrfTokenClearCookie() {
            // Act
            ResponseCookie[] cookies = cookieConfig.createClearAuthCookies();

            // Assert
            boolean hasCsrfToken = false;
            for (ResponseCookie cookie : cookies) {
                if ("csrf_token".equals(cookie.getName())) {
                    hasCsrfToken = true;
                    assertThat(cookie.getValue()).isEmpty();
                    assertThat(cookie.getMaxAge().isZero()).isTrue();
                    assertThat(cookie.getPath()).isEqualTo("/");
                    assertThat(cookie.isHttpOnly()).isFalse();
                }
            }
            assertThat(hasCsrfToken).isTrue();
        }
    }

    @Nested
    @DisplayName("Security Attributes Verification")
    class SecurityAttributesTests {

        @BeforeEach
        void setUp() {
            cookieConfig = new CookieConfig();
            ReflectionTestUtils.setField(cookieConfig, "secureCookie", true);
            ReflectionTestUtils.setField(cookieConfig, "cookieDomain", "");
        }

        @Test
        @DisplayName("Access token should be HttpOnly to prevent XSS")
        void accessTokenShouldBeHttpOnly_ToPreventXSS() {
            ResponseCookie cookie = cookieConfig.createAccessTokenCookie("token");
            assertThat(cookie.isHttpOnly())
                    .as("Access token must be HttpOnly to prevent XSS attacks")
                    .isTrue();
        }

        @Test
        @DisplayName("Refresh token should be HttpOnly to prevent XSS")
        void refreshTokenShouldBeHttpOnly_ToPreventXSS() {
            ResponseCookie cookie = cookieConfig.createRefreshTokenCookie("token");
            assertThat(cookie.isHttpOnly())
                    .as("Refresh token must be HttpOnly to prevent XSS attacks")
                    .isTrue();
        }

        @Test
        @DisplayName("Refresh token should have Strict SameSite for extra security")
        void refreshTokenShouldHaveStrictSameSite_ForExtraSecurity() {
            ResponseCookie cookie = cookieConfig.createRefreshTokenCookie("token");
            assertThat(cookie.getSameSite())
                    .as("Refresh token should use Strict SameSite for maximum CSRF protection")
                    .isEqualTo("Strict");
        }

        @Test
        @DisplayName("CSRF token should NOT be HttpOnly (JS must read it)")
        void csrfTokenShouldNotBeHttpOnly_JsMustReadIt() {
            ResponseCookie cookie = cookieConfig.createCsrfTokenCookie("token");
            assertThat(cookie.isHttpOnly())
                    .as("CSRF token must NOT be HttpOnly so JavaScript can read it")
                    .isFalse();
        }

        @Test
        @DisplayName("Refresh token path should be restricted to auth endpoints")
        void refreshTokenPathShouldBeRestricted_ToAuthEndpoints() {
            ResponseCookie cookie = cookieConfig.createRefreshTokenCookie("token");
            assertThat(cookie.getPath())
                    .as("Refresh token should only be sent to auth endpoints")
                    .isEqualTo("/api/v1/auth");
        }
    }
}
