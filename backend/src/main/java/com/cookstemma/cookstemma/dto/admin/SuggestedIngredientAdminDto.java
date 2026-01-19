package com.cookstemma.cookstemma.dto.admin;

import com.cookstemma.cookstemma.domain.entity.ingredient.UserSuggestedIngredient;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
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
        String rejectionReason,
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
                .rejectionReason(entity.getRejectionReason())
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
