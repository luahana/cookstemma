package com.pairingplanet.pairing_planet.dto.comment;

import com.pairingplanet.pairing_planet.domain.entity.comment.Comment;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.user.UserDto;

import java.time.Instant;
import java.util.UUID;


public record CommentResponseDto(
        UUID id,
        Long parentId,
        String content,
        VerdictType currentVerdict,
        boolean isSwitched, // FR-61-1: 아이콘 표시용
        int likeCount,
        boolean isLikedByMe, // 내가 좋아요 눌렀는지
        Instant createdAt,
        UserDto writer // 닉네임, 프로필 등
) {
    public static CommentResponseDto from(Comment c, boolean isLikedByMe) {
        // Switched 판단 로직: 처음이랑 지금이랑 다르면 true
        boolean switched = c.getInitialVerdict() != c.getCurrentVerdict();

        return new CommentResponseDto(
                c.getPublicId(),
                c.getParentId(),
                c.isDeleted() ? "삭제된 댓글입니다." : c.getContent(),
                c.getCurrentVerdict(),
                switched,
                c.getLikeCount(),
                isLikedByMe,
                c.getCreatedAt(),
                new UserDto(c.getUserId(), "User" + c.getUserId()) // 실제론 User 엔티티에서 조회
        );
    }
}