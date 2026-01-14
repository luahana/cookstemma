package com.pairingplanet.pairing_planet.dto.recipe;

import java.util.List;
import java.util.UUID;

public record RecipeSummaryDto(
        UUID publicId,
        String foodName,
        UUID foodMasterPublicId,
        String title,
        String description,
        String culinaryLocale,
        UUID creatorPublicId,  // Creator's publicId for profile navigation
        String creatorName,
        String thumbnail,
        Integer variantCount,
        Integer logCount,      // Activity count: number of cooking logs
        UUID parentPublicId,
        UUID rootPublicId,
        String rootTitle,      // Root recipe title for variants (lineage display)
        Integer servings,      // Number of servings
        String cookingTimeRange, // Cooking time range enum
        List<String> hashtags  // Hashtag names (first 3)
) {}