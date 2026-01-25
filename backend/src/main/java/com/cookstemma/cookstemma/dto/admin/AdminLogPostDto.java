package com.cookstemma.cookstemma.dto.admin;

import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO for admin log post management.
 * Contains all relevant log post data for admin listing and management.
 */
@Builder
public record AdminLogPostDto(
        UUID publicId,
        String content,
        String creatorUsername,
        UUID creatorPublicId,
        UUID recipePublicId,
        String recipeTitle,
        int commentCount,
        int likeCount,
        boolean isPrivate,
        Instant createdAt
) {
}
