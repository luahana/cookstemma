package com.pairingplanet.pairing_planet.dto.follow;

import java.util.List;

public record FollowListResponse(
        List<FollowerDto> content,
        boolean hasNext,
        int page,
        int size
) {}
