package com.pairingplanet.pairing_planet.dto.image;

import lombok.Builder;

import java.util.UUID;

@Builder
public record ImageUploadResponseDto(
        UUID imagePublicId,      // [추가] 이미지 식별 UUID
        String imageUrl,
        String originalFilename
) {}