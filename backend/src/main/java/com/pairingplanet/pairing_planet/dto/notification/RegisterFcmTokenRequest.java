package com.pairingplanet.pairing_planet.dto.notification;

import com.pairingplanet.pairing_planet.domain.enums.DeviceType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record RegisterFcmTokenRequest(
    @NotBlank String fcmToken,
    @NotNull DeviceType deviceType,
    String deviceId
) {}
