package com.cookstemma.cookstemma.dto.comment;

import java.time.Instant;
import java.util.UUID;

public record CommentResponseDto(
    UUID publicId,
    String content,
    UUID creatorPublicId,
    String creatorUsername,
    String creatorProfileImageUrl,
    Integer replyCount,
    Integer likeCount,
    Boolean isLikedByCurrentUser,
    Boolean isEdited,
    Boolean isDeleted,
    Boolean isHidden,
    Instant createdAt
) {}
