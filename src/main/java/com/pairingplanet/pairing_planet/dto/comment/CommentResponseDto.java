package com.pairingplanet.pairing_planet.dto.comment;

import com.pairingplanet.pairing_planet.domain.entity.comment.Comment;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.user.UserDto;

import java.time.Instant;
import java.util.UUID;


public record CommentResponseDto(
        UUID id,
        UUID parentPublicId, // [변경] 내부 ID 대신 Public ID 노출
        String content,
        VerdictType currentVerdict,
        boolean isSwitched,
        int likeCount,
        boolean isLikedByMe,
        Instant createdAt,
        UserDto writer
) {
    public static CommentResponseDto from(Comment c, User writer, boolean isLikedByMe, String urlPrefix) {
        boolean switched = c.getInitialVerdict() != c.getCurrentVerdict();

        return new CommentResponseDto(
                c.getPublicId(),
                null, // 필요 시 부모의 Public ID 조회 로직 추가 가능
                c.isDeleted() ? "삭제된 댓글입니다." : c.getContent(),
                c.getCurrentVerdict(),
                switched,
                c.getLikeCount(),
                isLikedByMe,
                c.getCreatedAt(),
                // [수정] 실제 User 정보를 UserDto에 매핑
                UserDto.from(writer, urlPrefix)
        );
    }
}