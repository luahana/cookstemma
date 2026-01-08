package com.pairingplanet.pairing_planet.dto.notification;

import java.util.List;

public record NotificationListResponse(
    List<NotificationDto> notifications,
    long unreadCount,
    boolean hasNext
) {}
