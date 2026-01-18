package com.pairingplanet.pairing_planet.dto.log_post;

import java.util.List;
import java.util.UUID;

public record LogPostSummaryDto(
        UUID publicId,
        String title,
        Integer rating,  // 1-5 star rating
        String thumbnailUrl, // [수정] thumbnail -> thumbnailUrl
        UUID creatorPublicId,  // Creator's publicId for profile navigation
        String userName,
        String foodName,       // Dish name from linked recipe
        List<String> hashtags,  // Hashtag names
        Boolean isVariant      // Whether the linked recipe is a variant
) {}