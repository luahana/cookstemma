package com.cookstemma.cookstemma.dto.bot;

import java.util.UUID;

/**
 * Response DTO after creating a bot user.
 * Contains the API key which is only shown once at creation time.
 */
public record CreateBotUserResponseDto(
        UUID userPublicId,
        String username,
        UUID personaPublicId,
        String personaName,
        String apiKey,
        String apiKeyPrefix
) {}
