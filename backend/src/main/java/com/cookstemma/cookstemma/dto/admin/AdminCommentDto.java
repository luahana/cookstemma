package com.cookstemma.cookstemma.dto.admin;

import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO for admin comment management.
 * Contains all relevant comment data for admin listing and management.
 */
@Builder
public record AdminCommentDto(
        UUID publicId,
        String content,
        String creatorUsername,
        UUID creatorPublicId,
        UUID logPostPublicId,
        boolean isTopLevel,
        int replyCount,
        int likeCount,
        Instant createdAt
) {
}
