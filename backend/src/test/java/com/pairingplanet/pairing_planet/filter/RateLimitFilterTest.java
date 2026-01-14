package com.pairingplanet.pairing_planet.filter;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.BucketConfiguration;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

/**
 * Unit tests for RateLimitFilter.
 * Tests rate limiting behavior for authentication endpoints.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RateLimitFilterTest {

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    private RateLimitFilter rateLimitFilter;
    private Map<String, BucketConfiguration> rateLimitConfigurations;

    @BeforeEach
    void setUp() {
        rateLimitConfigurations = new HashMap<>();

        // Configure rate limit: 3 requests per minute for login endpoint
        BucketConfiguration loginConfig = BucketConfiguration.builder()
                .addLimit(Bandwidth.simple(3, Duration.ofMinutes(1)))
                .build();
        rateLimitConfigurations.put("/api/v1/auth/web/social-login", loginConfig);

        // Configure rate limit: 5 requests per minute for reissue endpoint
        BucketConfiguration reissueConfig = BucketConfiguration.builder()
                .addLimit(Bandwidth.simple(5, Duration.ofMinutes(1)))
                .build();
        rateLimitConfigurations.put("/api/v1/auth/web/reissue", reissueConfig);
    }

    @Nested
    @DisplayName("Rate Limit Disabled")
    class RateLimitDisabledTests {

        @BeforeEach
        void setUp() {
            rateLimitFilter = new RateLimitFilter(rateLimitConfigurations, false);
        }

        @Test
        @DisplayName("Should pass through when rate limiting is disabled")
        void shouldPassThrough_WhenRateLimitDisabled() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");

            // Act
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(filterChain).doFilter(request, response);
            verify(response, never()).setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        }
    }

    @Nested
    @DisplayName("Rate Limit Enabled")
    class RateLimitEnabledTests {

        private StringWriter responseWriter;

        @BeforeEach
        void setUp() throws Exception {
            rateLimitFilter = new RateLimitFilter(rateLimitConfigurations, true);
            responseWriter = new StringWriter();
            lenient().when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        }

        @Test
        @DisplayName("Should allow request within rate limit")
        void shouldAllowRequest_WithinRateLimit() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");
            when(request.getRemoteAddr()).thenReturn("192.168.1.100");

            // Act
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(filterChain).doFilter(request, response);
            verify(response, never()).setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        }

        @Test
        @DisplayName("Should block request when rate limit exceeded")
        void shouldBlockRequest_WhenRateLimitExceeded() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");
            when(request.getRemoteAddr()).thenReturn("192.168.1.101");

            // Act - Make 3 requests (within limit), then 4th request (exceeds limit)
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Reset mock to verify the 4th request
            reset(filterChain);

            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Assert - 4th request should be blocked
            verify(response).setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            verify(response).setContentType(MediaType.APPLICATION_JSON_VALUE);
            verify(filterChain, never()).doFilter(request, response);
            assertThat(responseWriter.toString()).contains("RATE_LIMIT_EXCEEDED");
        }

        @Test
        @DisplayName("Should track rate limits separately per IP")
        void shouldTrackRateLimitsSeparately_PerIP() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");

            // First IP: exhaust limit
            when(request.getRemoteAddr()).thenReturn("192.168.1.1");
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Reset to track new IP's calls
            reset(filterChain);

            // Second IP: should still have full quota
            when(request.getRemoteAddr()).thenReturn("192.168.1.2");
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Assert - Second IP should pass
            verify(filterChain).doFilter(request, response);
        }

        @Test
        @DisplayName("Should use X-Forwarded-For header when present")
        void shouldUseXForwardedFor_WhenPresent() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");
            when(request.getHeader("X-Forwarded-For")).thenReturn("10.0.0.1, 192.168.1.1");
            when(request.getRemoteAddr()).thenReturn("172.16.0.1");

            // Act - Make 3 requests
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            reset(filterChain);

            // 4th request with same X-Forwarded-For
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Assert - Should be blocked (uses first IP from X-Forwarded-For)
            verify(response).setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        }

        @Test
        @DisplayName("Should use X-Real-IP header when X-Forwarded-For is absent")
        void shouldUseXRealIP_WhenXForwardedForAbsent() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");
            when(request.getHeader("X-Forwarded-For")).thenReturn(null);
            when(request.getHeader("X-Real-IP")).thenReturn("10.0.0.2");

            // Act - exhaust limit
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            reset(filterChain);

            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Assert - Should be blocked
            verify(response).setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        }

        @Test
        @DisplayName("Should skip GET requests")
        void shouldSkipGetRequests() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("GET");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");

            // Act
            boolean shouldNotFilter = rateLimitFilter.shouldNotFilter(request);

            // Assert
            assertThat(shouldNotFilter).isTrue();
        }

        @Test
        @DisplayName("Should skip endpoints without rate limit configuration")
        void shouldSkipEndpoints_WithoutRateLimitConfig() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");

            // Act
            boolean shouldNotFilter = rateLimitFilter.shouldNotFilter(request);

            // Assert
            assertThat(shouldNotFilter).isTrue();
        }

        @Test
        @DisplayName("Should not skip POST to rate-limited endpoint")
        void shouldNotSkipPost_ToRateLimitedEndpoint() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");

            // Act
            boolean shouldNotFilter = rateLimitFilter.shouldNotFilter(request);

            // Assert
            assertThat(shouldNotFilter).isFalse();
        }
    }

    @Nested
    @DisplayName("Rate Limit Response Format")
    class RateLimitResponseFormatTests {

        private StringWriter responseWriter;

        @BeforeEach
        void setUp() throws Exception {
            rateLimitFilter = new RateLimitFilter(rateLimitConfigurations, true);
            responseWriter = new StringWriter();
            when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        }

        @Test
        @DisplayName("Should return proper JSON error response when rate limited")
        void shouldReturnProperJsonError_WhenRateLimited() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/social-login");
            when(request.getRemoteAddr()).thenReturn("192.168.1.200");

            // Exhaust rate limit
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);
            rateLimitFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(response).setStatus(429);
            verify(response).setContentType("application/json");
            verify(response).setCharacterEncoding("UTF-8");

            String responseBody = responseWriter.toString();
            assertThat(responseBody).contains("\"code\":\"RATE_LIMIT_EXCEEDED\"");
            assertThat(responseBody).contains("\"message\":\"Too many requests. Please try again later.\"");
        }
    }
}
