package com.cookstemma.cookstemma.security;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // Skip JWT processing for auth endpoints (login, logout, etc.)
        String path = request.getRequestURI();
        if (path.startsWith("/api/v1/auth/")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = resolveToken(request);

        // Access Token 유효성 검증
        if (token != null && tokenProvider.validateToken(token)) {
            UUID publicId = UUID.fromString(tokenProvider.getSubject(token));

            // [수정] DB 조회를 통해 UserPrincipal 생성
            User user = userRepository.findByPublicId(publicId)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            UserPrincipal principal = new UserPrincipal(user);

            UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                    principal, null, principal.getAuthorities()
            );
            SecurityContextHolder.getContext().setAuthentication(authentication);
        }
        filterChain.doFilter(request, response);
    }

    /**
     * Resolves the JWT token from the request.
     * Priority 1: Authorization header (mobile clients)
     * Priority 2: access_token cookie (web clients)
     */
    private String resolveToken(HttpServletRequest request) {
        // Priority 1: Authorization header (for mobile clients)
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }

        // Priority 2: Cookie (for web clients)
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            return Arrays.stream(cookies)
                    .filter(cookie -> "access_token".equals(cookie.getName()))
                    .map(Cookie::getValue)
                    .findFirst()
                    .orElse(null);
        }

        return null;
    }
}