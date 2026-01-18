package com.pairingplanet.pairing_planet.dto.admin;

import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;

public record SuggestedIngredientFilterDto(
        String suggestedName,
        IngredientType ingredientType,
        String localeCode,
        SuggestionStatus status,
        String username,
        String sortBy,
        String sortOrder
) {
    public SuggestedIngredientFilterDto {
        if (sortBy == null || sortBy.isBlank()) {
            sortBy = "createdAt";
        }
        if (sortOrder == null || sortOrder.isBlank()) {
            sortOrder = "desc";
        }
    }
}
