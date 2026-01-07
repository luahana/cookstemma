package com.pairingplanet.pairing_planet.dto.log_post;

import java.util.List;
import java.util.UUID;

public record CreateLogRequestDto(
        UUID recipePublicId,
        String title,
        String content,
        String outcome,  // SUCCESS, PARTIAL, FAILED
        List<UUID> imagePublicIds, // [수정] String imageUrls -> UUID imagePublicIds
        List<String> hashtags // 해시태그 목록
) {}