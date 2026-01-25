package com.cookstemma.cookstemma.dto.follow;

import java.util.List;

public record FollowListResponse(
        List<FollowerDto> content,
        boolean hasNext,
        int page,
        int size
) {}
