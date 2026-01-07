package com.pairingplanet.pairing_planet.dto.auth;

import java.util.UUID;

public record AuthResponseDto(
        String accessToken,
        String refreshToken, // RTR로 인해 매번 새로 발급됨
        UUID userPublicId,
        String username
) {}