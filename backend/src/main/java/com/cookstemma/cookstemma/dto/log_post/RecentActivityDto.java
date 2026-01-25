package com.cookstemma.cookstemma.dto.log_post;

import lombok.Builder;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * DTO for home feed activity section.
 * Shows recent cooking logs with recipe context.
 */
@Builder
public record RecentActivityDto(
        UUID logPublicId,
        Integer rating,           // 1-5 star rating
        String thumbnailUrl,      // Log's first image
        String userName,       // Who cooked
        String recipeTitle,       // What recipe was followed
        UUID recipePublicId,      // Link to recipe
        String foodName,          // Food name for display
        Instant createdAt,        // When the log was created
        List<String> hashtags,    // Hashtag names for display
        Integer commentCount      // Number of comments on this log
) {}
