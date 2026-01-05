package com.pairingplanet.pairing_planet.dto.autocomplete;

import lombok.Builder;

import java.util.UUID;

@Builder
public record AutocompleteDto(
        UUID publicId,
        String name,
        String type,      // "FOOD" or "CATEGORY"
        Double score      // 유사도 점수 (디버깅/정렬용)
) {}