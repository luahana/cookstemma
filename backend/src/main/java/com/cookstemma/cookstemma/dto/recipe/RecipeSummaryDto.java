package com.cookstemma.cookstemma.dto.recipe;

import java.util.List;
import java.util.UUID;

/**
 * Recipe summary DTO with pre-localized title/description.
 * The title and description fields contain values for the requested locale,
 * resolved server-side from the translations map.
 */
public record RecipeSummaryDto(
        UUID publicId,
        String foodName,
        UUID foodMasterPublicId,
        String title,           // Localized title (resolved from titleTranslations)
        String description,     // Localized description (resolved from descriptionTranslations)
        String cookingStyle,
        UUID creatorPublicId,   // Creator's publicId for profile navigation
        String userName,
        String thumbnail,
        Integer variantCount,
        Integer logCount,       // Activity count: number of cooking logs
        UUID parentPublicId,
        UUID rootPublicId,
        String rootTitle,       // Root recipe title for variants (lineage display)
        Integer servings,       // Number of servings
        String cookingTimeRange, // Cooking time range enum
        List<String> hashtags   // Hashtag names (first 3)
) {}