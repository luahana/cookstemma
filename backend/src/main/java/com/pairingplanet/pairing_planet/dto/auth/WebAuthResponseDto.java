package com.pairingplanet.pairing_planet.dto.auth;

import java.util.UUID;

/**
 * Response DTO for web authentication.
 * Tokens are sent via HttpOnly cookies, so they are NOT included in the response body.
 * Only user information is returned.
 */
public record WebAuthResponseDto(
        UUID userPublicId,
        String username
) {
    /**
     * Creates a WebAuthResponseDto from a full AuthResponseDto.
     * Tokens are excluded since they will be sent via cookies.
     */
    public static WebAuthResponseDto from(AuthResponseDto authResponse) {
        return new WebAuthResponseDto(
                authResponse.userPublicId(),
                authResponse.username()
        );
    }
}
