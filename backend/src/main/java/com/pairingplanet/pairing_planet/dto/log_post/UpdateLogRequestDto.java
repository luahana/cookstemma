package com.pairingplanet.pairing_planet.dto.log_post;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

import java.util.List;
import java.util.UUID;

public record UpdateLogRequestDto(
        String title,
        @NotBlank(message = "요리 후기는 필수입니다")
        String content,
        @NotBlank(message = "요리 결과는 필수입니다")
        @Pattern(regexp = "SUCCESS|PARTIAL|FAILED", message = "요리 결과는 SUCCESS, PARTIAL, FAILED 중 하나여야 합니다")
        String outcome,
        List<String> hashtags,
        List<UUID> imagePublicIds  // Optional: update images if provided
) {}
