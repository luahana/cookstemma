package com.cookstemma.cookstemma.dto.admin;

import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO for admin recipe management.
 * Contains all relevant recipe data for admin listing and management.
 */
@Builder
public record AdminRecipeDto(
        UUID publicId,
        String title,
        String cookingStyle,
        String creatorUsername,
        UUID creatorPublicId,
        int variantCount,
        int logCount,
        int viewCount,
        int saveCount,
        boolean isPrivate,
        Instant createdAt
) {
}
