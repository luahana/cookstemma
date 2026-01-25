package com.cookstemma.cookstemma.dto.hashtag;

import java.util.UUID;

public record HashtagWithCountDto(
    UUID publicId,
    String name,
    long recipeCount,
    long logPostCount,
    long totalCount
) {}
