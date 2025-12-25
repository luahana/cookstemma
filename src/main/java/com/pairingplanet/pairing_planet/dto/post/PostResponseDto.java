package com.pairingplanet.pairing_planet.dto.post;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.post.DailyPost;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.post.RecipePost;
import com.pairingplanet.pairing_planet.domain.entity.post.ReviewPost;
import lombok.Builder;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Builder
public record PostResponseDto(
        // --- [Common] 모든 포스트 공통 필드 ---
        UUID id,
        String type,            // "DAILY", "REVIEW", "RECIPE" (프론트 분기 처리용)
        String content,
        List<String> imageUrls,
        Instant createdAt,
        Boolean isPrivate,

        // 페어링 정보 (PairingMap에서 추출)
        String food1Name,
        String food2Name,

        // 카운트 정보
        int geniusCount,
        int daringCount,
        int pickyCount,
        int savedCount,
        int commentCount,

        // --- [Review] 리뷰 전용 필드 (null 가능) ---
        String reviewTitle,     // title
        Boolean verdictEnabled, // ReviewPost에만 있음

        // --- [Recipe] 레시피 전용 필드 (null 가능) ---
        String recipeTitle,     // title
        String ingredients,     // 간단 텍스트 재료
        Integer cookingTime,
        Integer difficulty,
        Map<String, Object> recipeData // 상세 레시피 JSON
) {
    public static PostResponseDto from(Post post, String urlPrefix) {
        // 1. 공통 빌더 생성
        var builder = PostResponseDto.builder()
                .id(post.getPublicId())
                .content(post.getContent())
                .imageUrls(post.getImages().stream()
                        .map(img -> urlPrefix + "/" + img.getStoredFilename())
                        .collect(Collectors.toList()))
                .createdAt(post.getCreatedAt())
                .isPrivate(post.isPrivate())
                .geniusCount(post.getGeniusCount())
                .daringCount(post.getDaringCount())
                .pickyCount(post.getPickyCount())
                .savedCount(post.getSavedCount())
                .commentCount(post.getCommentCount());

        // 페어링 정보 매핑 (Null check 권장)
        if (post.getPairing() != null) {
            // 예시: 로케일 처리는 서비스 레이어에서 하거나, 여기서는 단순화
            // builder.food1Name(...);
        }

        // 2. 타입별 분기 처리 (instanceof 패턴 매칭)
        if (post instanceof DailyPost) {
            builder.type("DAILY");
        }
        else if (post instanceof ReviewPost review) {
            builder.type("REVIEW")
                    .reviewTitle(review.getTitle())
                    .verdictEnabled(review.isVerdictEnabled());
        }
        else if (post instanceof RecipePost recipe) {
            builder.type("RECIPE")
                    .recipeTitle(recipe.getTitle())
                    .ingredients(recipe.getIngredients())
                    .cookingTime(recipe.getCookingTime())
                    .difficulty(recipe.getDifficulty()); // Entity 필드명 매핑
        }

        return builder.build();
    }
}