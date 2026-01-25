package com.cookstemma.cookstemma.dto.recipe;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/**
 * Step DTO with pre-localized description.
 * The description field contains the value for the requested locale,
 * resolved server-side from the descriptionTranslations map.
 */
public record StepDto(
        @NotNull(message = "단계 번호는 필수입니다")
        @Min(value = 1, message = "단계 번호는 1 이상이어야 합니다")
        Integer stepNumber,
        @NotBlank(message = "단계 설명은 필수입니다")
        @Size(max = 2000, message = "단계 설명은 2000자 이하여야 합니다")
        String description,  // Localized step description
        UUID imagePublicId,
        String imageUrl
) {}
