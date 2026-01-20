package com.cookstemma.cookstemma.dto.recipe;

import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.MeasurementUnit;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Ingredient DTO with pre-localized name.
 * The name field contains the value for the requested locale,
 * resolved server-side from the nameTranslations map.
 */
public record IngredientDto(
        @NotBlank(message = "재료명은 필수입니다")
        @Size(max = 50, message = "재료명은 50자 이하여야 합니다")
        String name,  // Localized ingredient name

        /**
         * Numeric quantity for structured measurements (e.g., 2.5).
         */
        Double quantity,

        /**
         * Standardized unit for structured measurements.
         */
        MeasurementUnit unit,

        @NotNull(message = "재료 유형은 필수입니다")
        IngredientType type
) {}
