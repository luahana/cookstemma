package com.pairingplanet.pairing_planet.dto.post;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import lombok.Builder;

import java.time.Instant;
import java.util.List;

@Builder
public record MyPostResponseDto(
        Long id,
        String content,
        List<String> imageUrls,
        Instant createdAt,
        boolean isPrivate, // 자물쇠 아이콘 표시용

        // 페어링 정보 (간략)
        String food1Name,
        String food2Name,

        // 통계 정보
        int savedCount,
        int commentCount,

        String cursor // 다음 페이지 요청용 커서
) {
    public static MyPostResponseDto from(Post post, String nextCursor) {
        // 페어링 정보 추출 (예시: 로케일 처리는 서비스에서 하거나 간단히 'en' 사용)
        String f1 = post.getPairing().getFood1().getName().get("en");
        String f2 = post.getPairing().getFood2() != null ? post.getPairing().getFood2().getName().get("en") : null;

        return MyPostResponseDto.builder()
                .id(post.getId())
                .content(post.getContent())
                .imageUrls(post.getImageUrls())
                .createdAt(post.getCreatedAt())
                .isPrivate(post.isPrivate())
                .food1Name(f1)
                .food2Name(f2)
                .savedCount(post.getSavedCount())
                .commentCount(post.getCommentCount())
                .cursor(nextCursor)
                .build();
    }
}