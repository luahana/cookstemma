package com.pairingplanet.pairing_planet.dto.post;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import lombok.Builder;
import java.time.Instant;


@Builder
public record PostDto(
        Long id,
        String content,
        String locale,

        // --- 커서 페이지네이션을 위한 필수 필드 추가 ---
        Double popularityScore,   // Popularity 커서용
        Double controversyScore,  // Controversy 커서용
        Integer commentCount,     // TrendScore 계산 및 TrendContro 커서용
        Integer savedCount,       // TrendScore 계산용

        Instant createdAt,        // Fresh 커서용
        String categoryTag        // 디버깅용 태그
) {
    public static PostDto from(Post post, String tag) {
        return PostDto.builder()
                .id(post.getId())
                .content(post.getContent())
                .locale(post.getLocale())

                // Entity에서 값 매핑
                .popularityScore(post.getPopularityScore())
                .controversyScore(post.getControversyScore())
                .commentCount(post.getCommentCount())
                .savedCount(post.getSavedCount())

                .createdAt(post.getCreatedAt())
                .categoryTag(tag)
                .build();
    }
}