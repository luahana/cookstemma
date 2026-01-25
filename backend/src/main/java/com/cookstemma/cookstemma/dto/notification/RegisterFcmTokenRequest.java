package com.cookstemma.cookstemma.dto.notification;

import com.cookstemma.cookstemma.domain.enums.DeviceType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record RegisterFcmTokenRequest(
    @NotBlank String fcmToken,
    @NotNull DeviceType deviceType,
    String deviceId
) {}
