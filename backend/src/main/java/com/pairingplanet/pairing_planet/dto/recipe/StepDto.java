package com.pairingplanet.pairing_planet.dto.recipe;

import java.util.UUID;
public record StepDto(
        Integer stepNumber,
        String description,
        UUID imagePublicId, // [추가] 식별용 UUID
        String imageUrl     // [유지] 표시용 URL
) {}