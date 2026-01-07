package com.pairingplanet.pairing_planet.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class JwtTokenProviderTest {

    private JwtTokenProvider jwtTokenProvider;
    private static final String TEST_SECRET = "dGVzdC1zZWNyZXQta2V5LWZvci1wYWlyaW5nLXBsYW5ldC1hcHBsaWNhdGlvbi10ZXN0aW5n";

    @BeforeEach
    void setUp() {
        jwtTokenProvider = new JwtTokenProvider(TEST_SECRET);
    }

    @Nested
    @DisplayName("Access Token Tests")
    class AccessTokenTests {

        @Test
        @DisplayName("Should create valid access token with publicId and role")
        void createAccessToken_Success() {
            UUID publicId = UUID.randomUUID();
            String role = "USER";

            String token = jwtTokenProvider.createAccessToken(publicId, role);

            assertThat(token).isNotBlank();
            assertThat(jwtTokenProvider.validateToken(token)).isTrue();
            assertThat(jwtTokenProvider.getSubject(token)).isEqualTo(publicId.toString());
            assertThat(jwtTokenProvider.getRole(token)).isEqualTo(role);
        }

        @Test
        @DisplayName("Should extract correct subject from access token")
        void getSubject_ReturnsCorrectPublicId() {
            UUID publicId = UUID.randomUUID();
            String token = jwtTokenProvider.createAccessToken(publicId, "USER");

            String subject = jwtTokenProvider.getSubject(token);

            assertThat(subject).isEqualTo(publicId.toString());
        }

        @Test
        @DisplayName("Should extract correct role from access token")
        void getRole_ReturnsCorrectRole() {
            UUID publicId = UUID.randomUUID();
            String token = jwtTokenProvider.createAccessToken(publicId, "ADMIN");

            String role = jwtTokenProvider.getRole(token);

            assertThat(role).isEqualTo("ADMIN");
        }
    }

    @Nested
    @DisplayName("Refresh Token Tests")
    class RefreshTokenTests {

        @Test
        @DisplayName("Should create valid refresh token without role")
        void createRefreshToken_Success() {
            UUID publicId = UUID.randomUUID();

            String token = jwtTokenProvider.createRefreshToken(publicId);

            assertThat(token).isNotBlank();
            assertThat(jwtTokenProvider.validateToken(token)).isTrue();
            assertThat(jwtTokenProvider.getSubject(token)).isEqualTo(publicId.toString());
            assertThat(jwtTokenProvider.getRole(token)).isNull();
        }
    }

    @Nested
    @DisplayName("Token Validation Tests")
    class ValidationTests {

        @Test
        @DisplayName("Should return false for invalid token")
        void validateToken_InvalidToken_ReturnsFalse() {
            assertThat(jwtTokenProvider.validateToken("invalid.token.here")).isFalse();
        }

        @Test
        @DisplayName("Should return false for null token")
        void validateToken_NullToken_ReturnsFalse() {
            assertThat(jwtTokenProvider.validateToken(null)).isFalse();
        }

        @Test
        @DisplayName("Should return false for empty token")
        void validateToken_EmptyToken_ReturnsFalse() {
            assertThat(jwtTokenProvider.validateToken("")).isFalse();
        }

        @Test
        @DisplayName("Should return true for valid token")
        void validateToken_ValidToken_ReturnsTrue() {
            UUID publicId = UUID.randomUUID();
            String token = jwtTokenProvider.createAccessToken(publicId, "USER");

            assertThat(jwtTokenProvider.validateToken(token)).isTrue();
        }
    }
}
