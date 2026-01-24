package com.cookstemma.cookstemma.dto.hashtag;

import java.util.UUID;

/**
 * DTO for popular hashtags with content counts.
 * Used by the /popular endpoint to return hashtags filtered by language.
 */
public record HashtagWithCountDto(
        UUID publicId,
        String name,
        long recipeCount,
        long logPostCount,
        long totalCount
) {
    /**
     * Create a HashtagWithCountDto with calculated totalCount.
     */
    public static HashtagWithCountDto of(UUID publicId, String name, long recipeCount, long logPostCount) {
        return new HashtagWithCountDto(publicId, name, recipeCount, logPostCount, recipeCount + logPostCount);
    }
}
