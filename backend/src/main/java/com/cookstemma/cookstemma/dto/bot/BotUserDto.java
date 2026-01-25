package com.cookstemma.cookstemma.dto.bot;

import com.cookstemma.cookstemma.domain.entity.user.User;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO for bot user information (without sensitive API key data).
 */
public record BotUserDto(
        UUID publicId,
        String username,
        UUID personaPublicId,
        String personaName,
        String locale,
        String cookingStyle,
        boolean isActive,
        Instant createdAt
) {
    public static BotUserDto from(User user) {
        return new BotUserDto(
                user.getPublicId(),
                user.getUsername(),
                user.getPersona() != null ? user.getPersona().getPublicId() : null,
                user.getPersona() != null ? user.getPersona().getName() : null,
                user.getLocale(),
                user.getDefaultCookingStyle(),
                user.isBot() && user.getStatus().name().equals("ACTIVE"),
                user.getCreatedAt()
        );
    }
}
