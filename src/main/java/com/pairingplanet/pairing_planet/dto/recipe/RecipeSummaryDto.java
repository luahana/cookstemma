package com.pairingplanet.pairing_planet.dto.recipe;

import java.util.UUID;

public record RecipeSummaryDto(
        UUID publicId,
        String foodName,
        UUID foodMasterPublicId,
        String title,
        String description,
        String culinaryLocale,
        String creatorName,
        String thumbnail,
        Integer variantCount,
        UUID parentPublicId,
        UUID rootPublicId
) {}