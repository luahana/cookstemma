package com.pairingplanet.pairing_planet.dto.recipe;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record StepDto(
        @NotNull(message = "단계 번호는 필수입니다")
        @Min(value = 1, message = "단계 번호는 1 이상이어야 합니다")
        Integer stepNumber,
        @NotBlank(message = "단계 설명은 필수입니다")
        String description,
        UUID imagePublicId,
        String imageUrl
) {}
