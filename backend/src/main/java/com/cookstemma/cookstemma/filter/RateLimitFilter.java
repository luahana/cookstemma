package com.cookstemma.cookstemma.filter;

import com.cookstemma.cookstemma.security.JwtTokenProvider;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.BucketConfiguration;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rate limiting filter that applies request limits per IP address.
 * Protects authentication endpoints from brute force attacks.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RateLimitFilter extends OncePerRequestFilter {

    private final Map<String, BucketConfiguration> rateLimitConfigurations;
    private final boolean rateLimitEnabled;
    private final JwtTokenProvider jwtTokenProvider;

    // Cache of buckets per key (IP + endpoint)
    private final Map<String, Bucket> bucketCache = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        if (!rateLimitEnabled) {
            filterChain.doFilter(request, response);
            return;
        }

        String path = request.getRequestURI();
        BucketConfiguration config = findMatchingConfig(path);

        if (config == null) {
            // No rate limit for this endpoint
            filterChain.doFilter(request, response);
            return;
        }

        // Check if request is from a bot (exempt from rate limiting)
        if (isBotRequest(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientIp = getClientIp(request);
        String bucketKey = buildBucketKey(path, clientIp);

        Bucket bucket = bucketCache.computeIfAbsent(bucketKey, k -> createBucket(config));

        if (bucket.tryConsume(1)) {
            filterChain.doFilter(request, response);
        } else {
            log.warn("Rate limit exceeded for IP: {} on endpoint: {}", clientIp, path);
            sendRateLimitResponse(response);
        }
    }

    private BucketConfiguration findMatchingConfig(String path) {
        return rateLimitConfigurations.get(path);
    }

    private Bucket createBucket(BucketConfiguration config) {
        return Bucket.builder()
                .addLimit(config.getBandwidths()[0])
                .build();
    }

    private String buildBucketKey(String path, String clientIp) {
        return "rate_limit:" + path + ":" + clientIp;
    }

    private String getClientIp(HttpServletRequest request) {
        // Check for forwarded headers (when behind proxy/load balancer)
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            // Take the first IP in the chain (original client)
            return xForwardedFor.split(",")[0].trim();
        }

        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }

        return request.getRemoteAddr();
    }

    private boolean isBotRequest(HttpServletRequest request) {
        String token = resolveToken(request);
        if (token != null && jwtTokenProvider.validateToken(token)) {
            String role = jwtTokenProvider.getRole(token);
            return "BOT".equals(role);
        }
        return false;
    }

    private String resolveToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        // Check cookie for web clients
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            return Arrays.stream(cookies)
                    .filter(c -> "access_token".equals(c.getName()))
                    .map(Cookie::getValue)
                    .findFirst()
                    .orElse(null);
        }
        return null;
    }

    private void sendRateLimitResponse(HttpServletResponse response) throws IOException {
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"code\":\"RATE_LIMIT_EXCEEDED\",\"message\":\"Too many requests. Please try again later.\"}");
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // Only filter POST requests to auth endpoints
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String path = request.getRequestURI();
        return !rateLimitConfigurations.containsKey(path);
    }
}
