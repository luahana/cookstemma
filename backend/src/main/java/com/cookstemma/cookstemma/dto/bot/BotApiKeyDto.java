package com.cookstemma.cookstemma.dto.bot;

import com.cookstemma.cookstemma.domain.entity.bot.BotApiKey;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO for API key information (does not include the actual key or hash).
 */
@Builder
public record BotApiKeyDto(
        UUID publicId,
        String keyPrefix,
        String name,
        Instant lastUsedAt,
        Instant expiresAt,
        boolean isActive,
        Instant createdAt
) {
    public static BotApiKeyDto from(BotApiKey apiKey) {
        return BotApiKeyDto.builder()
                .publicId(apiKey.getPublicId())
                .keyPrefix(apiKey.getKeyPrefix())
                .name(apiKey.getName())
                .lastUsedAt(apiKey.getLastUsedAt())
                .expiresAt(apiKey.getExpiresAt())
                .isActive(apiKey.isActive())
                .createdAt(apiKey.getCreatedAt())
                .build();
    }
}
