package com.pairingplanet.pairing_planet.dto.log_post;

import java.util.List;
import java.util.UUID;

public record LogPostSummaryDto(
        UUID publicId,
        String title,
        String outcome,  // SUCCESS, PARTIAL, FAILED
        String thumbnailUrl, // [수정] thumbnail -> thumbnailUrl
        UUID creatorPublicId,  // Creator's publicId for profile navigation
        String creatorName,
        String foodName,       // Dish name from linked recipe
        List<String> hashtags  // Hashtag names
) {}