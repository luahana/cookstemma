package com.pairingplanet.pairing_planet.dto.post;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.dto.image.PostImageDto;
import lombok.Builder;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Builder
public record MyPostResponseDto(
        UUID id,
        String content,
        List<PostImageDto> images,
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
    public static MyPostResponseDto from(Post post, String nextCursor, String urlPrefix) {
        // 페어링 정보 추출 (예시: 로케일 처리는 서비스에서 하거나 간단히 'en' 사용)
        String f1 = post.getPairing().getFood1().getName().get("en");
        String f2 = post.getPairing().getFood2() != null ? post.getPairing().getFood2().getName().get("en") : null;

        return MyPostResponseDto.builder()
                .id(post.getPublicId())
                .content(post.getContent())
                .images(post.getImages().stream()
                        // [수정] PostImageDto.from 호출 시 urlPrefix를 전달합니다.
                        .map(img -> PostImageDto.from(img, urlPrefix))
                        .toList())
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