package com.pairingplanet.pairing_planet.dto.search;

import java.time.Instant;
import java.util.UUID;

public record SearchHistoryDto(
        UUID id,                // 히스토리 자체의 Public ID
        UUID pairingPublicId,   // 연결된 페어링의 Public ID
        String food1Name,
        String food2Name,
        String whenTag,
        String dietaryTag,
        Instant searchedAt
) {}