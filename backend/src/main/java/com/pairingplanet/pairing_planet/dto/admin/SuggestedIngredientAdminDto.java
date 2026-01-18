package com.pairingplanet.pairing_planet.dto.admin;

import com.pairingplanet.pairing_planet.domain.entity.ingredient.UserSuggestedIngredient;
import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record SuggestedIngredientAdminDto(
        UUID publicId,
        String suggestedName,
        IngredientType ingredientType,
        String localeCode,
        SuggestionStatus status,
        UUID userPublicId,
        String username,
        UUID autocompleteItemPublicId,
        Instant createdAt,
        Instant updatedAt
) {
    public static SuggestedIngredientAdminDto from(UserSuggestedIngredient entity) {
        return SuggestedIngredientAdminDto.builder()
                .publicId(entity.getPublicId())
                .suggestedName(entity.getSuggestedName())
                .ingredientType(entity.getIngredientType())
                .localeCode(entity.getLocaleCode())
                .status(entity.getStatus())
                .userPublicId(entity.getUser() != null ? entity.getUser().getPublicId() : null)
                .username(entity.getUser() != null ? entity.getUser().getUsername() : null)
                .autocompleteItemPublicId(entity.getAutocompleteItemRef() != null
                        ? entity.getAutocompleteItemRef().getPublicId()
                        : null)
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
