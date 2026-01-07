package com.pairingplanet.pairing_planet.dto.user;

import com.pairingplanet.pairing_planet.domain.enums.Gender;
import java.time.LocalDate;
import java.util.UUID;

public record UpdateProfileRequestDto(
        String username,
        UUID profileImagePublicId, // [수정] String profileImageUrl -> UUID profileImagePublicId
        Gender gender,
        LocalDate birthDate,
        UUID preferredDietaryId,
        Boolean marketingAgreed
) {}