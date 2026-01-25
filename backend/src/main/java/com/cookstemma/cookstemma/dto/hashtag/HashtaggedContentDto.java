package com.cookstemma.cookstemma.dto.hashtag;

import java.util.List;
import java.util.UUID;

/**
 * DTO representing content (recipe or log) that has hashtags.
 * Used for the unified hashtag feed that combines both content types.
 */
public record HashtaggedContentDto(
        String type,              // "recipe" or "log"
        UUID publicId,
        String title,
        String thumbnailUrl,
        UUID creatorPublicId,
        String userName,
        List<String> hashtags,
        String foodName,          // For recipes
        String cookingStyle,      // For recipes
        Integer rating,           // For logs (1-5 star rating)
        String recipeTitle,       // For logs (linked recipe's title)
        Boolean isPrivate
) {}
