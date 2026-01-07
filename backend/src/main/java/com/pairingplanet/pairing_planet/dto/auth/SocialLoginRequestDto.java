package com.pairingplanet.pairing_planet.dto.auth;

import com.pairingplanet.pairing_planet.domain.enums.Provider;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record SocialLoginRequestDto(
        @NotBlank String idToken, // Firebase에서 발급받은 ID Token
        @NotBlank String locale   // 유저의 시스템 언어 설정
) {}