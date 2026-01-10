package com.pairingplanet.pairing_planet.dto.recipe;

import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import com.pairingplanet.pairing_planet.domain.enums.MeasurementUnit;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record IngredientDto(
        @NotBlank(message = "재료명은 필수입니다")
        String name,

        /**
         * Legacy amount field - free-text like "2 cups" or "a pinch".
         * For backward compatibility. New clients should use quantity + unit.
         */
        String amount,

        /**
         * Numeric quantity for structured measurements (e.g., 2.5).
         * Optional - use with unit for structured input.
         */
        Double quantity,

        /**
         * Standardized unit for structured measurements.
         * Optional - use with quantity for structured input.
         */
        MeasurementUnit unit,

        @NotNull(message = "재료 유형은 필수입니다")
        IngredientType type
) {
    /**
     * Check if this DTO uses structured measurements.
     */
    public boolean hasStructuredMeasurement() {
        return quantity != null && unit != null;
    }
}
