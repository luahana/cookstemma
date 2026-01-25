package com.cookstemma.cookstemma.dto.admin;

import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record UntranslatedRecipeDto(
        UUID publicId,
        String title,
        String cookingStyle,
        TranslationStatus translationStatus,
        String lastError,
        Integer translatedLocaleCount,
        Integer totalLocaleCount,
        String creatorUsername,
        Instant createdAt
) {
}
