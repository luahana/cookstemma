package com.pairingplanet.pairing_planet.dto.autocomplete;

import lombok.Builder;

@Builder
public record AutocompleteDto(
        Long id,
        String name,
        String type,      // "FOOD" or "CATEGORY"
        Double score      // 유사도 점수 (디버깅/정렬용)
) {}