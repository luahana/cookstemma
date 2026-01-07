package com.pairingplanet.pairing_planet.dto.recipe;

import lombok.Builder;

import java.util.UUID;

@Builder
public record TrendingTreeDto(
        UUID rootRecipeId,
        String title,
        String foodName,      // 음식 이름
        String culinaryLocale,
        String thumbnail,     // 썸네일 URL
        Long variantCount,    // 변형 수
        Long logCount,        // 로그 수
        String latestChangeSummary // 최근 변형 사유 요약
) {}