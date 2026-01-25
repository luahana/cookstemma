package com.cookstemma.cookstemma.dto.recipe;

import com.cookstemma.cookstemma.dto.log_post.RecentActivityDto;
import lombok.Builder;

import java.util.List;

@Builder
public record HomeFeedResponseDto(
        List<RecentActivityDto> recentActivity,   // 최근 요리 활동 (로그)
        List<RecipeSummaryDto> recentRecipes,     // 최근 생성된 레시피
        List<TrendingTreeDto> trendingTrees       // "이 레시피, 이렇게 바뀌고 있어요" 섹션용
) {}