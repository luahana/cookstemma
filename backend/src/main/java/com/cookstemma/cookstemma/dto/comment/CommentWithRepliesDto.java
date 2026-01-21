package com.cookstemma.cookstemma.dto.comment;

import java.util.List;

public record CommentWithRepliesDto(
    CommentResponseDto comment,
    List<CommentResponseDto> replies,
    Boolean hasMoreReplies
) {}
