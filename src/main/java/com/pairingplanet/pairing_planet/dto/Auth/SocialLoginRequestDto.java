package com.pairingplanet.pairing_planet.dto.Auth;

import com.pairingplanet.pairing_planet.domain.enums.Provider;
import jakarta.validation.constraints.NotBlank;

public record SocialLoginRequestDto(
        @NotBlank Provider provider,
        @NotBlank String providerUserId,
        String email,
        String username,
        String profileImageUrl,
        @NotBlank String socialAccessToken, // 암호화되어 저장될 값
        String socialRefreshToken
) {}