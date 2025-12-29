package com.pairingplanet.pairing_planet.dto.post;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.post.DailyPost;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.post.RecipePost;
import com.pairingplanet.pairing_planet.domain.entity.post.ReviewPost;
import lombok.Builder;
import java.time.Instant;
import java.util.UUID;

@Builder
public record PostDto(
        UUID id,
        String type,           // DAILY, REVIEW, RECIPE
        String url,            // 메인 이미지 URL
        String content,
        String locale,
        String thumbnailUrl,   // 썸네일 URL

        Double popularityScore,
        Double controversyScore,
        Integer commentCount,
        Integer savedCount,

        Instant createdAt,
        String categoryTag     // [수정] PairingMap의 컨텍스트 라벨 (예: "저녁식사 · 비건")
) {
    /**
     * Entity를 DTO로 변환합니다.
     * @param post 변환할 포스트 엔티티
     * @param contextLabel FeedService에서 조립된 컨텍스트 문자열
     * @param urlPrefix 이미지 서버 주소
     */
    public static PostDto from(Post post, String contextLabel, String urlPrefix) {
        // 1. 포스트 타입 결정 (DiscriminatorValue 기반)
        String dtype = "DAILY";
        if (post instanceof ReviewPost) dtype = "REVIEW";
        else if (post instanceof RecipePost) dtype = "RECIPE";

        // 2. 이미지 처리: 리스트의 첫 번째 이미지를 대표 이미지로 사용
        Image mainImage = (post.getImages() != null && !post.getImages().isEmpty())
                ? post.getImages().get(0)
                : null;

        String mainImageUrl = (mainImage != null)
                ? urlPrefix + "/" + mainImage.getStoredFilename()
                : null;

        // 3. DTO 빌드
        return PostDto.builder()
                .id(post.getPublicId()) // UUID
                .type(dtype)
                .url(mainImageUrl)
                .thumbnailUrl(mainImageUrl)
                .content(post.getContent())
                .locale(post.getLocale())
                .popularityScore(post.getPopularityScore())
                .controversyScore(post.getControversyScore())
                .commentCount(post.getCommentCount())
                .savedCount(post.getSavedCount())
                .createdAt(post.getCreatedAt())
                .categoryTag(contextLabel) // "When · Dietary" 라벨 저장
                .build();
    }
}