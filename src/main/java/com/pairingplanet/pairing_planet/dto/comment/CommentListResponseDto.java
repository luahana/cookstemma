package com.pairingplanet.pairing_planet.dto.comment;

import java.util.List;

public record CommentListResponseDto(
        List<CommentResponseDto> bestComments, // 상단 고정 (배댓)
        List<CommentResponseDto> list,         // 일반 리스트
        String nextCursor,                  // 다음 페이지 커서
        boolean hasNext
) {}