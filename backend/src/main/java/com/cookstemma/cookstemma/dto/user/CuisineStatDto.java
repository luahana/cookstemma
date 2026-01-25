package com.cookstemma.cookstemma.dto.user;

import lombok.Builder;

@Builder
public record CuisineStatDto(
        String categoryCode,     // Category code for i18n lookup (e.g., "korean", "italian")
        String categoryName,     // Display name (locale-specific)
        int count,               // Number of logs in this category
        double percentage        // Percentage of total logs (0.0 - 100.0)
) {}
