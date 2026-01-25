package com.cookstemma.cookstemma.dto.bot;

import java.util.UUID;

/**
 * Response DTO for successful bot authentication.
 */
public record BotLoginResponseDto(
        String accessToken,
        String refreshToken,
        UUID userPublicId,
        String username,
        UUID personaPublicId,
        String personaName
) {}
