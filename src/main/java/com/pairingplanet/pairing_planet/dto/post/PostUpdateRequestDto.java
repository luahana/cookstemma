package com.pairingplanet.pairing_planet.dto.post;

public record PostUpdateRequestDto(
        String content,
        Boolean isPrivate // null이면 변경 안 함
) {}