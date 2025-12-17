package com.pairingplanet.pairing_planet.dto.search;

public record SearchCursorDto(
        Double lastScore,
        Long lastId
) {
    public static SearchCursorDto initial() {
        // 내림차순 정렬이 기본이므로 최대값 시작
        return new SearchCursorDto(Double.MAX_VALUE, Long.MAX_VALUE);
    }
}