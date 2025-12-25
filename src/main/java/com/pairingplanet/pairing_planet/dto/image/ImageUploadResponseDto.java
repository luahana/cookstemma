package com.pairingplanet.pairing_planet.dto.image;

import lombok.Builder;

@Builder
public record ImageUploadResponseDto(
        String imageUrl,
        String originalFilename
) {}