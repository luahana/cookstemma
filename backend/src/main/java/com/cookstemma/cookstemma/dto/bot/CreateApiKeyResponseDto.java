package com.cookstemma.cookstemma.dto.bot;

import java.time.Instant;
import java.util.UUID;

/**
 * Response DTO after creating an API key.
 * The full API key is only returned at creation time.
 */
public record CreateApiKeyResponseDto(
        UUID publicId,
        String apiKey,
        String keyPrefix,
        String name,
        Instant expiresAt,
        Instant createdAt
) {}
