package com.pairingplanet.pairing_planet.dto.post;

import java.util.List;

public record PostResponseDto(
        Long postId,
        String food1Name,
        String food2Name,
        List<String> imageUrls,
        String content,
        Boolean verdictEnabled,
        Boolean commentsEnabled,
        Boolean isPrivate
) {}