package com.cookstemma.cookstemma.dto.log_post;

import java.util.List;
import java.util.UUID;

public record LogPostSummaryDto(
        UUID publicId,
        String title,
        String content,  // Cooking notes (for display in recipe detail logs gallery)
        Integer rating,  // 1-5 star rating
        String thumbnailUrl, // [수정] thumbnail -> thumbnailUrl
        UUID creatorPublicId,  // Creator's publicId for profile navigation
        String userName,
        String foodName,       // Dish name from linked recipe
        String recipeTitle,    // Linked recipe's title
        List<String> hashtags,  // Hashtag names
        Boolean isVariant,     // Whether the linked recipe is a variant
        Boolean isPrivate      // Whether this log is private
) {}