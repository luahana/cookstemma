package com.pairingplanet.pairing_planet.dto.admin;

import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;

public record SuggestedFoodFilterDto(
        String suggestedName,
        String localeCode,
        SuggestionStatus status,
        String username,
        String sortBy,
        String sortOrder
) {
    public SuggestedFoodFilterDto {
        // Default sort order if not provided
        if (sortBy == null || sortBy.isBlank()) {
            sortBy = "createdAt";
        }
        if (sortOrder == null || sortOrder.isBlank()) {
            sortOrder = "desc";
        }
    }
}
