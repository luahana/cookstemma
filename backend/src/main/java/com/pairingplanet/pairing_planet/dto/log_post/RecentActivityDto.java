package com.pairingplanet.pairing_planet.dto.log_post;

import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO for home feed activity section.
 * Shows recent cooking logs with recipe context.
 */
@Builder
public record RecentActivityDto(
        UUID logPublicId,
        String outcome,           // SUCCESS, PARTIAL, FAILED
        String thumbnailUrl,      // Log's first image
        String creatorName,       // Who cooked
        String recipeTitle,       // What recipe was followed
        UUID recipePublicId,      // Link to recipe
        String foodName,          // Food name for display
        Instant createdAt         // When the log was created
) {}
