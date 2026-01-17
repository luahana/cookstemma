package com.pairingplanet.pairing_planet.dto.user;

import com.pairingplanet.pairing_planet.domain.enums.Gender;
import com.pairingplanet.pairing_planet.domain.enums.MeasurementPreference;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

public record UpdateProfileRequestDto(
        @Size(max = 50, message = "Username cannot exceed 50 characters")
        String username,
        UUID profileImagePublicId, // [수정] String profileImageUrl -> UUID profileImagePublicId
        Gender gender,
        LocalDate birthDate,
        UUID preferredDietaryId,
        Boolean marketingAgreed,
        String locale,  // 언어 설정: ko-KR, en-US
        String defaultFoodStyle,  // 기본 요리 스타일: ISO country code (e.g., "KR", "US")
        MeasurementPreference measurementPreference,  // 측정 단위 선호: METRIC, US, ORIGINAL

        @Size(max = 150, message = "Bio cannot exceed 150 characters")
        String bio,

        @Pattern(
                regexp = "^$|^(https?://)?(www\\.)?(youtube\\.com/(channel/|c/|user/|@)[\\w-]+|youtu\\.be/[\\w-]+)/?$",
                message = "Invalid YouTube URL format"
        )
        String youtubeUrl,

        @Pattern(
                regexp = "^$|^@?[a-zA-Z0-9._]{1,30}$|^(https?://)?(www\\.)?instagram\\.com/[a-zA-Z0-9._]{1,30}/?$",
                message = "Invalid Instagram handle or URL format"
        )
        String instagramHandle
) {}