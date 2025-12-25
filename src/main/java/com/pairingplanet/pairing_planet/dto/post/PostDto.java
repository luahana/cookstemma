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
        String type, // [추가] DAILY, REVIEW, RECIPE
        String url,
        String content,
        String locale,
        String thumbnailUrl,

        Double popularityScore,
        Double controversyScore,
        Integer commentCount,
        Integer savedCount,

        Instant createdAt,
        String categoryTag
) {
    public static PostDto from(Post post, String tag, String urlPrefix) {
        String dtype = "DAILY";
        if (post instanceof ReviewPost) dtype = "REVIEW";
        else if (post instanceof RecipePost) dtype = "RECIPE";

        // [추가] 게시글의 이미지 리스트에서 첫 번째 이미지를 가져옵니다.
        Image mainImage = (post.getImages() != null && !post.getImages().isEmpty())
                ? post.getImages().get(0)
                : null;

        String mainImageUrl = (mainImage != null)
                ? urlPrefix + "/" + mainImage.getStoredFilename()
                : null;

        return PostDto.builder()
                .id(post.getPublicId())
                .url(mainImageUrl) // 첫 번째 이미지 URL
                .type(dtype)
                .content(post.getContent())
                .locale(post.getLocale())
                .thumbnailUrl(mainImageUrl) // 썸네일도 동일하게 처리하거나 별도 로직 적용
                .popularityScore(post.getPopularityScore())
                .controversyScore(post.getControversyScore())
                .commentCount(post.getCommentCount())
                .savedCount(post.getSavedCount())
                .createdAt(post.getCreatedAt())
                .categoryTag(tag)
                .build();
    }
}