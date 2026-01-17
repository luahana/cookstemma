package com.pairingplanet.pairing_planet.dto.admin;

import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record UserSuggestedFoodDto(
        UUID publicId,
        String suggestedName,
        String localeCode,
        SuggestionStatus status,
        UUID userPublicId,
        String username,
        UUID masterFoodPublicId,
        Instant createdAt,
        Instant updatedAt
) {
    public static UserSuggestedFoodDto from(UserSuggestedFood entity) {
        return UserSuggestedFoodDto.builder()
                .publicId(entity.getPublicId())
                .suggestedName(entity.getSuggestedName())
                .localeCode(entity.getLocaleCode())
                .status(entity.getStatus())
                .userPublicId(entity.getUser().getPublicId())
                .username(entity.getUser().getUsername())
                .masterFoodPublicId(entity.getMasterFoodRef() != null
                        ? entity.getMasterFoodRef().getPublicId()
                        : null)
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
