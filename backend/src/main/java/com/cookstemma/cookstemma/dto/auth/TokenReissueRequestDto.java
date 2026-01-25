package com.cookstemma.cookstemma.dto.auth;

import jakarta.validation.constraints.NotBlank;

public record TokenReissueRequestDto(
        @NotBlank String refreshToken // 만료된 Access Token을 갱신하기 위한 토큰
) {}