package com.pairingplanet.pairing_planet.dto.hashtag;

import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;

import java.util.UUID;

public record HashtagDto(
        UUID publicId,
        String name
) {
    public static HashtagDto from(Hashtag hashtag) {
        return new HashtagDto(hashtag.getPublicId(), hashtag.getName());
    }
}
