package com.pairingplanet.pairing_planet.dto.post;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import lombok.Builder;

import java.time.LocalDateTime;
import java.util.List;

@Builder
public record SavedPostDto(
        Long postId,
        boolean isDeleted,      // 프론트엔드에서 UI 분기 처리용 (Ghost Card 여부)

        // --- 콘텐츠 정보 (삭제 시 null) ---
        String content,
        List<String> imageUrls,
        String creatorName,
        String creatorProfileUrl,

        // --- 페어링 정보 (삭제되어도 항상 노출) ---
        // 실제 PairingMap 엔티티 구조에 맞춰 getter 호출 필요
        String food1Name,
        String food2Name,
        String whenTagName,
        String dietaryTagName,

        LocalDateTime savedAt,
        String cursor // 다음 페이지 요청을 위한 커서 값
) {
    public static SavedPostDto from(Post post, LocalDateTime savedAt, String nextCursor) {
        boolean deleted = post.isDeleted();

        // 페어링 정보 추출 (Post.getPairing() 통해 접근)
        // 로케일 처리는 서비스 레이어에서 하거나, 여기서는 단순화하여 표현
        var pairing = post.getPairing();
        String f1 = pairing.getFood1().getName().get("en");
        String f2 = pairing.getFood2() != null ? pairing.getFood2().getName().get("en") : null;

        // When/Dietary 등은 PairingMap 내부 구조에 따름
        String when = "Dinner"; // 예시
        String diet = "Vegan";  // 예시

        if (deleted) {
            // [Ghost Card] 삭제된 경우: 콘텐츠/유저 정보 숨김
            return SavedPostDto.builder()
                    .postId(post.getId())
                    .isDeleted(true)
                    .food1Name(f1).food2Name(f2)
                    .whenTagName(when).dietaryTagName(diet)
                    .savedAt(savedAt)
                    .cursor(nextCursor)
                    .build();
        } else {
            // [Normal Card] 정상 게시물
            return SavedPostDto.builder()
                    .postId(post.getId())
                    .isDeleted(false)
                    .content(post.getContent())
                    .imageUrls(post.getImageUrls())
                    .creatorName(post.getCreator().getUsername())
                    .creatorProfileUrl(post.getCreator().getProfileImageUrl())
                    .food1Name(f1).food2Name(f2)
                    .whenTagName(when).dietaryTagName(diet)
                    .savedAt(savedAt)
                    .cursor(nextCursor)
                    .build();
        }
    }
}