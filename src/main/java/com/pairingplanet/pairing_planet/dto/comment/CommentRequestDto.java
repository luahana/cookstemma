package com.pairingplanet.pairing_planet.dto.comment;

public record CommentRequestDto(
        Long postId,
        Long parentId, // 대댓글일 경우 필수
        String content
) {}