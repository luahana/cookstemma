package com.pairingplanet.pairing_planet.dto.recipe;

import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record IngredientDto(
        @NotBlank(message = "재료명은 필수입니다")
        String name,
        String amount,
        @NotNull(message = "재료 유형은 필수입니다")
        IngredientType type
) {}
