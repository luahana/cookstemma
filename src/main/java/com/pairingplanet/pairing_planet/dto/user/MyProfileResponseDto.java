package com.pairingplanet.pairing_planet.dto.user;

import lombok.Builder;

@Builder
public record MyProfileResponseDto(
        UserDto user,
        long recipeCount, // 내가 만든 레시피 수
        long logCount     // 내가 남긴 로그 수
) {}