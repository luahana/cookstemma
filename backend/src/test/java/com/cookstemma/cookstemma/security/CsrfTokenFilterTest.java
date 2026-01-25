package com.cookstemma.cookstemma.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import java.io.PrintWriter;
import java.io.StringWriter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

/**
 * Unit tests for CsrfTokenFilter.
 * Tests CSRF protection for cookie-based authentication.
 */
@ExtendWith(MockitoExtension.class)
class CsrfTokenFilterTest {

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    private CsrfTokenFilter csrfTokenFilter;
    private StringWriter responseWriter;

    @BeforeEach
    void setUp() throws Exception {
        csrfTokenFilter = new CsrfTokenFilter();
        responseWriter = new StringWriter();
        lenient().when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
    }

    @Nested
    @DisplayName("Safe HTTP Methods")
    class SafeMethodsTests {

        @ParameterizedTest
        @DisplayName("Should skip CSRF check for safe HTTP methods")
        @ValueSource(strings = {"GET", "HEAD", "OPTIONS", "TRACE"})
        void shouldSkipCsrfCheck_ForSafeMethods(String method) throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn(method);

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(filterChain).doFilter(request, response);
            verify(response, never()).setStatus(HttpStatus.FORBIDDEN.value());
        }
    }

    @Nested
    @DisplayName("Exempt Paths")
    class ExemptPathsTests {

        @Test
        @DisplayName("Should skip CSRF check for CSRF token endpoint")
        void shouldSkipCsrfCheck_ForCsrfTokenEndpoint() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/auth/web/csrf-token");

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(filterChain).doFilter(request, response);
            verify(response, never()).setStatus(HttpStatus.FORBIDDEN.value());
        }
    }

    @Nested
    @DisplayName("Mobile Clients (Authorization Header)")
    class MobileClientsTests {

        @Test
        @DisplayName("Should skip CSRF check when Authorization header is present")
        void shouldSkipCsrfCheck_WhenAuthorizationHeaderPresent() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn("Bearer some-token");

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(filterChain).doFilter(request, response);
            verify(response, never()).setStatus(HttpStatus.FORBIDDEN.value());
        }

        @Test
        @DisplayName("Should check CSRF when Authorization header is null")
        void shouldCheckCsrf_WhenAuthorizationHeaderNull() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);

            Cookie accessCookie = new Cookie("access_token", "some-access-token");
            when(request.getCookies()).thenReturn(new Cookie[]{accessCookie});

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert - Should fail because no CSRF token
            verify(response).setStatus(HttpStatus.FORBIDDEN.value());
        }
    }

    @Nested
    @DisplayName("Non-Cookie Requests")
    class NonCookieRequestsTests {

        @Test
        @DisplayName("Should skip CSRF check when no access_token cookie")
        void shouldSkipCsrfCheck_WhenNoAccessTokenCookie() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);
            when(request.getCookies()).thenReturn(null);

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(filterChain).doFilter(request, response);
            verify(response, never()).setStatus(HttpStatus.FORBIDDEN.value());
        }

        @Test
        @DisplayName("Should skip CSRF check when cookies exist but no access_token")
        void shouldSkipCsrfCheck_WhenOtherCookiesButNoAccessToken() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);

            Cookie otherCookie = new Cookie("session_id", "some-session");
            when(request.getCookies()).thenReturn(new Cookie[]{otherCookie});

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(filterChain).doFilter(request, response);
            verify(response, never()).setStatus(HttpStatus.FORBIDDEN.value());
        }
    }

    @Nested
    @DisplayName("CSRF Validation")
    class CsrfValidationTests {

        @Test
        @DisplayName("Should pass when CSRF header matches cookie")
        void shouldPass_WhenCsrfHeaderMatchesCookie() throws Exception {
            // Arrange
            String csrfToken = "valid-csrf-token-123";

            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);
            when(request.getHeader("X-CSRF-Token")).thenReturn(csrfToken);

            Cookie accessCookie = new Cookie("access_token", "some-access-token");
            Cookie csrfCookie = new Cookie("csrf_token", csrfToken);
            when(request.getCookies()).thenReturn(new Cookie[]{accessCookie, csrfCookie});

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(filterChain).doFilter(request, response);
            verify(response, never()).setStatus(HttpStatus.FORBIDDEN.value());
        }

        @Test
        @DisplayName("Should fail when CSRF header is missing")
        void shouldFail_WhenCsrfHeaderMissing() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);
            when(request.getHeader("X-CSRF-Token")).thenReturn(null);

            Cookie accessCookie = new Cookie("access_token", "some-access-token");
            Cookie csrfCookie = new Cookie("csrf_token", "valid-csrf-token");
            when(request.getCookies()).thenReturn(new Cookie[]{accessCookie, csrfCookie});

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(response).setStatus(HttpStatus.FORBIDDEN.value());
            verify(filterChain, never()).doFilter(request, response);
        }

        @Test
        @DisplayName("Should fail when CSRF cookie is missing")
        void shouldFail_WhenCsrfCookieMissing() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);
            when(request.getHeader("X-CSRF-Token")).thenReturn("some-csrf-token");

            Cookie accessCookie = new Cookie("access_token", "some-access-token");
            when(request.getCookies()).thenReturn(new Cookie[]{accessCookie});

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(response).setStatus(HttpStatus.FORBIDDEN.value());
            verify(filterChain, never()).doFilter(request, response);
        }

        @Test
        @DisplayName("Should fail when CSRF header does not match cookie")
        void shouldFail_WhenCsrfHeaderDoesNotMatchCookie() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);
            when(request.getHeader("X-CSRF-Token")).thenReturn("wrong-token");

            Cookie accessCookie = new Cookie("access_token", "some-access-token");
            Cookie csrfCookie = new Cookie("csrf_token", "correct-token");
            when(request.getCookies()).thenReturn(new Cookie[]{accessCookie, csrfCookie});

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(response).setStatus(HttpStatus.FORBIDDEN.value());
            verify(filterChain, never()).doFilter(request, response);
        }
    }

    @Nested
    @DisplayName("CSRF Error Response")
    class CsrfErrorResponseTests {

        @Test
        @DisplayName("Should return proper JSON error response for CSRF failure")
        void shouldReturnProperJsonError_ForCsrfFailure() throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn("POST");
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);
            when(request.getHeader("X-CSRF-Token")).thenReturn(null);

            Cookie accessCookie = new Cookie("access_token", "some-access-token");
            when(request.getCookies()).thenReturn(new Cookie[]{accessCookie});

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert
            verify(response).setStatus(403);
            verify(response).setContentType(MediaType.APPLICATION_JSON_VALUE);
            verify(response).setCharacterEncoding("UTF-8");

            String responseBody = responseWriter.toString();
            assertThat(responseBody).contains("\"code\":\"CSRF_INVALID\"");
            assertThat(responseBody).contains("\"message\":\"Invalid or missing CSRF token\"");
        }
    }

    @Nested
    @DisplayName("Unsafe HTTP Methods")
    class UnsafeMethodsTests {

        @ParameterizedTest
        @DisplayName("Should check CSRF for unsafe HTTP methods")
        @ValueSource(strings = {"POST", "PUT", "PATCH", "DELETE"})
        void shouldCheckCsrf_ForUnsafeMethods(String method) throws Exception {
            // Arrange
            when(request.getMethod()).thenReturn(method);
            when(request.getRequestURI()).thenReturn("/api/v1/recipes");
            when(request.getHeader("Authorization")).thenReturn(null);

            Cookie accessCookie = new Cookie("access_token", "some-access-token");
            when(request.getCookies()).thenReturn(new Cookie[]{accessCookie});

            // Act
            csrfTokenFilter.doFilterInternal(request, response, filterChain);

            // Assert - Should fail because no CSRF token
            verify(response).setStatus(HttpStatus.FORBIDDEN.value());
            verify(filterChain, never()).doFilter(request, response);
        }
    }
}
