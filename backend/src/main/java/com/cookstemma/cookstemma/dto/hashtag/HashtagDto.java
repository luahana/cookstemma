package com.cookstemma.cookstemma.dto.hashtag;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;

import java.util.UUID;

public record HashtagDto(
        UUID publicId,
        String name
) {
    public static HashtagDto from(Hashtag hashtag) {
        return new HashtagDto(hashtag.getPublicId(), hashtag.getName());
    }
}
