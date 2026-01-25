package com.cookstemma.cookstemma.dto.recipe;

import lombok.Builder;

import java.util.UUID;

@Builder
public record TrendingTreeDto(
        UUID rootRecipeId,
        String title,
        String foodName,      // 음식 이름
        String cookingStyle,
        String thumbnail,     // 썸네일 URL
        Long variantCount,    // 변형 수
        Long logCount,        // 로그 수
        String latestChangeSummary, // 최근 변형 사유 요약
        String userName,   // 작성자 이름
        UUID creatorPublicId  // 작성자 publicId (프로필 링크용)
) {}