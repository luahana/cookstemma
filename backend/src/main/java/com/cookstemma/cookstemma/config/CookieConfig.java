package com.cookstemma.cookstemma.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseCookie;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * Configuration for creating secure authentication cookies.
 * Supports HttpOnly cookies for XSS protection.
 */
@Component
public class CookieConfig {

    @Value("${app.cookie.domain:}")
    private String cookieDomain;

    @Value("${app.cookie.secure:true}")
    private boolean secureCookie;

    // Token expiration times (matching JwtTokenProvider)
    private static final Duration ACCESS_TOKEN_EXPIRY = Duration.ofMinutes(30);
    private static final Duration REFRESH_TOKEN_EXPIRY = Duration.ofDays(14);
    private static final Duration CSRF_TOKEN_EXPIRY = Duration.ofHours(24);

    /**
     * Creates an HttpOnly cookie for the access token.
     * - HttpOnly: true (prevents XSS attacks)
     * - Secure: configurable (true in production)
     * - SameSite: Lax (allows top-level navigation)
     * - Path: "/" (sent with all requests)
     */
    public ResponseCookie createAccessTokenCookie(String token) {
        ResponseCookie.ResponseCookieBuilder builder = ResponseCookie.from("access_token", token)
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite("Lax")
                .path("/")
                .maxAge(ACCESS_TOKEN_EXPIRY);

        if (cookieDomain != null && !cookieDomain.isEmpty()) {
            builder.domain(cookieDomain);
        }

        return builder.build();
    }

    /**
     * Creates an HttpOnly cookie for the refresh token.
     * - HttpOnly: true (prevents XSS attacks)
     * - Secure: configurable (true in production)
     * - SameSite: Strict (more restrictive for refresh token)
     * - Path: "/api/v1/auth" (only sent to auth endpoints)
     */
    public ResponseCookie createRefreshTokenCookie(String token) {
        ResponseCookie.ResponseCookieBuilder builder = ResponseCookie.from("refresh_token", token)
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite("Strict")
                .path("/api/v1/auth")
                .maxAge(REFRESH_TOKEN_EXPIRY);

        if (cookieDomain != null && !cookieDomain.isEmpty()) {
            builder.domain(cookieDomain);
        }

        return builder.build();
    }

    /**
     * Creates a cookie for the CSRF token.
     * - HttpOnly: false (JavaScript needs to read it)
     * - Secure: configurable
     * - SameSite: Lax
     * - Path: "/"
     */
    public ResponseCookie createCsrfTokenCookie(String token) {
        ResponseCookie.ResponseCookieBuilder builder = ResponseCookie.from("csrf_token", token)
                .httpOnly(false) // JS needs to read this
                .secure(secureCookie)
                .sameSite("Lax")
                .path("/")
                .maxAge(CSRF_TOKEN_EXPIRY);

        if (cookieDomain != null && !cookieDomain.isEmpty()) {
            builder.domain(cookieDomain);
        }

        return builder.build();
    }

    /**
     * Creates a cookie that clears/expires an existing cookie.
     */
    public ResponseCookie createClearCookie(String name, String path) {
        ResponseCookie.ResponseCookieBuilder builder = ResponseCookie.from(name, "")
                .httpOnly(true)
                .secure(secureCookie)
                .path(path)
                .maxAge(0); // Immediately expire

        if (cookieDomain != null && !cookieDomain.isEmpty()) {
            builder.domain(cookieDomain);
        }

        return builder.build();
    }

    /**
     * Creates clear cookies for all auth-related cookies.
     */
    public ResponseCookie[] createClearAuthCookies() {
        return new ResponseCookie[]{
                createClearCookie("access_token", "/"),
                createClearCookie("refresh_token", "/api/v1/auth"),
                ResponseCookie.from("csrf_token", "")
                        .httpOnly(false)
                        .secure(secureCookie)
                        .path("/")
                        .maxAge(0)
                        .build()
        };
    }
}
