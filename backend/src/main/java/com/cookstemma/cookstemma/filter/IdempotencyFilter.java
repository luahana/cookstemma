package com.cookstemma.cookstemma.filter;

import com.cookstemma.cookstemma.domain.entity.idempotency.IdempotencyKey;
import com.cookstemma.cookstemma.repository.idempotency.IdempotencyKeyRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Optional;

/**
 * Filter that implements idempotency key pattern for POST/PATCH requests.
 *
 * When a client sends an Idempotency-Key header:
 * 1. If the key exists with the same request hash -> return cached response
 * 2. If the key exists with different request hash -> return 422 error
 * 3. If the key doesn't exist -> execute request, cache response
 *
 * Keys are scoped per user and expire after 24 hours.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class IdempotencyFilter extends OncePerRequestFilter {

    private static final String IDEMPOTENCY_KEY_HEADER = "Idempotency-Key";

    private final IdempotencyKeyRepository idempotencyKeyRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // Only process POST and PATCH requests
        String method = request.getMethod();
        if (!("POST".equals(method) || "PATCH".equals(method))) {
            filterChain.doFilter(request, response);
            return;
        }

        // Check for Idempotency-Key header
        String idempotencyKeyValue = request.getHeader(IDEMPOTENCY_KEY_HEADER);
        if (idempotencyKeyValue == null || idempotencyKeyValue.isBlank()) {
            // No idempotency key - proceed normally
            filterChain.doFilter(request, response);
            return;
        }

        // Get authenticated user
        Long userId = getCurrentUserId();
        if (userId == null) {
            // Not authenticated - proceed normally (auth filter will handle)
            filterChain.doFilter(request, response);
            return;
        }

        // Wrap request to read body multiple times
        ContentCachingRequestWrapper wrappedRequest = new ContentCachingRequestWrapper(request);
        ContentCachingResponseWrapper wrappedResponse = new ContentCachingResponseWrapper(response);

        String requestPath = request.getRequestURI();

        // Check for existing idempotency key
        Optional<IdempotencyKey> existingKey = idempotencyKeyRepository
                .findByIdempotencyKeyAndUserId(idempotencyKeyValue, userId);

        if (existingKey.isPresent()) {
            IdempotencyKey cached = existingKey.get();

            // Check if expired
            if (cached.isExpired()) {
                log.debug("Idempotency key {} expired, deleting and processing as new request", idempotencyKeyValue);
                idempotencyKeyRepository.delete(cached);
            } else if (cached.hasCachedResponse()) {
                // We need to verify request hash, but body not yet read
                // Execute the filter chain to read body, then compare
                filterChain.doFilter(wrappedRequest, wrappedResponse);

                String requestHash = hashRequestBody(wrappedRequest.getContentAsByteArray());

                if (!cached.getRequestHash().equals(requestHash)) {
                    // Different request body with same key - error
                    log.warn("Idempotency key {} reused with different request body", idempotencyKeyValue);
                    wrappedResponse.resetBuffer();
                    wrappedResponse.setStatus(422); // Unprocessable Entity
                    wrappedResponse.setContentType("application/json");
                    wrappedResponse.getWriter().write("{\"error\": \"Idempotency key already used with different request\"}");
                    wrappedResponse.copyBodyToResponse();
                    return;
                }

                // Same request - return cached response
                log.info("Returning cached response for idempotency key {}", idempotencyKeyValue);
                wrappedResponse.resetBuffer();
                wrappedResponse.setStatus(cached.getResponseStatus());
                wrappedResponse.setContentType("application/json");
                if (cached.getResponseBody() != null) {
                    wrappedResponse.getWriter().write(cached.getResponseBody());
                }
                wrappedResponse.copyBodyToResponse();
                return;
            }
            // Key exists but no cached response yet (concurrent request) - proceed
        }

        // Execute the request
        filterChain.doFilter(wrappedRequest, wrappedResponse);

        // Get request hash after body is read
        String requestHash = hashRequestBody(wrappedRequest.getContentAsByteArray());

        // Cache the response
        try {
            int status = wrappedResponse.getStatus();
            String responseBody = new String(wrappedResponse.getContentAsByteArray(), StandardCharsets.UTF_8);

            // Create or update idempotency key
            IdempotencyKey key = existingKey.orElseGet(() ->
                    IdempotencyKey.create(idempotencyKeyValue, userId, requestPath, requestHash));
            key.storeResponse(status, responseBody);
            idempotencyKeyRepository.save(key);

            log.debug("Stored idempotency key {} with status {}", idempotencyKeyValue, status);
        } catch (Exception e) {
            log.error("Failed to store idempotency key: {}", e.getMessage());
            // Don't fail the request if caching fails
        }

        // Copy cached content to actual response
        wrappedResponse.copyBodyToResponse();
    }

    /**
     * Get the current user's ID from security context
     */
    private Long getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserPrincipal userPrincipal) {
            return userPrincipal.getId();
        }
        return null;
    }

    /**
     * Generate SHA-256 hash of request body
     */
    private String hashRequestBody(byte[] body) {
        if (body == null || body.length == 0) {
            return "empty";
        }
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(body);
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            log.error("SHA-256 not available", e);
            return "error";
        }
    }
}
