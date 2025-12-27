package com.pairingplanet.pairing_planet.dto.post;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.post.DailyPost;
import com.pairingplanet.pairing_planet.domain.entity.post.ReviewPost;
import com.pairingplanet.pairing_planet.domain.entity.post.RecipePost;
import lombok.Builder;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Builder
public record SavedPostDto(
        UUID id,
        String type,        // DAILY, REVIEW, RECIPE
        String title,       // 리뷰/레시피 제목 또는 food1Name
        String content,
        List<ImageResponse> images, // [{ "url": "..." }] 구조
        Instant createdAt,
        String food1Name,
        String food2Name,
        String cursor
) {
    public record ImageResponse(String url) {}

    public static SavedPostDto from(Post post, Instant savedAt, String nextCursor, String urlPrefix) {
        // 1. 페어링 정보 추출
        var pairing = post.getPairing();
        String f1 = pairing.getFood1().getName().get("en");
        String f2 = pairing.getFood2() != null ? pairing.getFood2().getName().get("en") : null;

        // 2. 타입 및 제목 판별
        String type = "DAILY";
        String title = f1; // 기본값은 food1Name

        if (post instanceof ReviewPost review) {
            type = "REVIEW";
            title = review.getTitle();
        } else if (post instanceof RecipePost recipe) {
            type = "RECIPE";
            title = recipe.getTitle();
        }

        // 3. 이미지 리스트 변환 (규격서의 객체 형태)
        List<ImageResponse> imageObjects = post.getImages().stream()
                .map(img -> new ImageResponse(urlPrefix + "/" + img.getStoredFilename()))
                .toList();

        return SavedPostDto.builder()
                .id(post.getPublicId())
                .type(type)
                .title(title)
                .content(post.getContent())
                .images(imageObjects)
                .createdAt(post.getCreatedAt())
                .food1Name(f1)
                .food2Name(f2)
                .cursor(nextCursor)
                .build();
    }
}