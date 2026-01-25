package com.cookstemma.cookstemma.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.util.Set;

/**
 * CSRF protection filter for cookie-based authentication.
 * Validates that the X-CSRF-Token header matches the csrf_token cookie.
 *
 * This filter only applies to:
 * - Requests with access_token cookie (web clients)
 * - Non-safe HTTP methods (POST, PUT, PATCH, DELETE)
 *
 * Mobile clients using Authorization header are exempt from CSRF protection
 * since they don't use cookies.
 */
@Slf4j
@Component
public class CsrfTokenFilter extends OncePerRequestFilter {

    private static final String CSRF_HEADER = "X-CSRF-Token";
    private static final String CSRF_COOKIE = "csrf_token";
    private static final String ACCESS_TOKEN_COOKIE = "access_token";

    // Safe HTTP methods that don't require CSRF protection
    private static final Set<String> SAFE_METHODS = Set.of("GET", "HEAD", "OPTIONS", "TRACE");

    // Paths exempt from CSRF (e.g., getting CSRF token)
    private static final Set<String> EXEMPT_PATHS = Set.of(
            "/api/v1/auth/web/csrf-token"
    );

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        // Skip for safe methods
        if (SAFE_METHODS.contains(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        // Skip for exempt paths
        if (EXEMPT_PATHS.contains(request.getRequestURI())) {
            filterChain.doFilter(request, response);
            return;
        }

        // Skip for mobile clients (using Authorization header, not cookies)
        if (request.getHeader("Authorization") != null) {
            filterChain.doFilter(request, response);
            return;
        }

        // Check if this is a cookie-based request
        String accessTokenCookie = getCookieValue(request, ACCESS_TOKEN_COOKIE);
        if (accessTokenCookie == null) {
            // Not a cookie-based request, skip CSRF check
            filterChain.doFilter(request, response);
            return;
        }

        // Validate CSRF token for cookie-based requests
        String headerToken = request.getHeader(CSRF_HEADER);
        String cookieToken = getCookieValue(request, CSRF_COOKIE);

        if (headerToken == null || cookieToken == null || !headerToken.equals(cookieToken)) {
            log.warn("CSRF validation failed for path: {} - header: {}, cookie: {}",
                    request.getRequestURI(),
                    headerToken != null ? "present" : "missing",
                    cookieToken != null ? "present" : "missing");
            sendCsrfErrorResponse(response);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String getCookieValue(HttpServletRequest request, String cookieName) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }
        return Arrays.stream(cookies)
                .filter(cookie -> cookieName.equals(cookie.getName()))
                .map(Cookie::getValue)
                .findFirst()
                .orElse(null);
    }

    private void sendCsrfErrorResponse(HttpServletResponse response) throws IOException {
        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"code\":\"CSRF_INVALID\",\"message\":\"Invalid or missing CSRF token\"}");
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // This filter should always run to check if CSRF validation is needed
        return false;
    }
}
