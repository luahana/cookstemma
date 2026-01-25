package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.config.CookieConfig;
import com.cookstemma.cookstemma.dto.auth.AuthResponseDto;
import com.cookstemma.cookstemma.dto.auth.SocialLoginRequestDto;
import com.cookstemma.cookstemma.dto.auth.TokenReissueRequestDto;
import com.cookstemma.cookstemma.dto.auth.WebAuthResponseDto;
import com.cookstemma.cookstemma.service.AuthService;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Web-specific authentication controller that uses HttpOnly cookies for token storage.
 * This provides enhanced security for browser-based clients by preventing XSS attacks.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth/web")
@RequiredArgsConstructor
public class WebAuthController {

    private final AuthService authService;
    private final CookieConfig cookieConfig;

    /**
     * Social login for web clients.
     * Tokens are set in HttpOnly cookies instead of response body.
     */
    @PostMapping("/social-login")
    public ResponseEntity<WebAuthResponseDto> socialLogin(
            @RequestBody @Valid SocialLoginRequestDto request,
            HttpServletResponse response) {

        AuthResponseDto authResult = authService.socialLogin(request);

        // Set HttpOnly cookies with tokens
        addAuthCookies(response, authResult.accessToken(), authResult.refreshToken());

        log.info("Web social login successful for user: {}", authResult.username());

        // Return user info only (tokens are in cookies)
        return ResponseEntity.ok(WebAuthResponseDto.from(authResult));
    }

    /**
     * Token reissue for web clients.
     * Reads refresh token from cookie and sets new tokens in cookies.
     */
    @PostMapping("/reissue")
    public ResponseEntity<WebAuthResponseDto> reissue(
            @CookieValue(name = "refresh_token", required = false) String refreshToken,
            HttpServletResponse response) {

        if (refreshToken == null || refreshToken.isEmpty()) {
            log.warn("Web token reissue failed: No refresh token cookie");
            return ResponseEntity.status(401).build();
        }

        try {
            AuthResponseDto authResult = authService.reissue(new TokenReissueRequestDto(refreshToken));

            // Update cookies with new tokens
            addAuthCookies(response, authResult.accessToken(), authResult.refreshToken());

            log.debug("Web token reissue successful for user: {}", authResult.username());

            return ResponseEntity.ok(WebAuthResponseDto.from(authResult));
        } catch (Exception e) {
            log.warn("Web token reissue failed: {}", e.getMessage());
            // Clear cookies on failure
            clearAuthCookies(response);
            return ResponseEntity.status(401).build();
        }
    }

    /**
     * Logout for web clients.
     * Clears all authentication cookies.
     */
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletResponse response) {
        clearAuthCookies(response);
        log.debug("Web logout: Cookies cleared");
        return ResponseEntity.ok().build();
    }

    /**
     * Get CSRF token.
     * Sets a non-HttpOnly CSRF cookie that JavaScript can read.
     * The frontend must include this token in X-CSRF-Token header for POST/PUT/DELETE requests.
     */
    @GetMapping("/csrf-token")
    public ResponseEntity<Void> getCsrfToken(HttpServletResponse response) {
        String csrfToken = UUID.randomUUID().toString();
        ResponseCookie csrfCookie = cookieConfig.createCsrfTokenCookie(csrfToken);
        response.addHeader(HttpHeaders.SET_COOKIE, csrfCookie.toString());
        return ResponseEntity.ok().build();
    }

    /**
     * Check authentication status.
     * Returns 200 if access token cookie is valid, 401 otherwise.
     */
    @GetMapping("/status")
    public ResponseEntity<Void> checkStatus() {
        // If this endpoint is reached, the JWT filter has already validated the token
        return ResponseEntity.ok().build();
    }

    private void addAuthCookies(HttpServletResponse response, String accessToken, String refreshToken) {
        ResponseCookie accessCookie = cookieConfig.createAccessTokenCookie(accessToken);
        ResponseCookie refreshCookie = cookieConfig.createRefreshTokenCookie(refreshToken);

        response.addHeader(HttpHeaders.SET_COOKIE, accessCookie.toString());
        response.addHeader(HttpHeaders.SET_COOKIE, refreshCookie.toString());
    }

    private void clearAuthCookies(HttpServletResponse response) {
        for (ResponseCookie cookie : cookieConfig.createClearAuthCookies()) {
            response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
        }
    }
}
