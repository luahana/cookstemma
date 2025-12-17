package com.pairingplanet.pairing_planet.dto.Auth;

import jakarta.validation.constraints.NotBlank;

public record TokenReissueRequestDto(
        @NotBlank String refreshToken // 만료된 Access Token을 갱신하기 위한 토큰
) {}