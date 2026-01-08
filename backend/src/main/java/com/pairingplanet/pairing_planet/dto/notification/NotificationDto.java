package com.pairingplanet.pairing_planet.dto.notification;

import com.pairingplanet.pairing_planet.domain.entity.notification.Notification;
import com.pairingplanet.pairing_planet.domain.enums.NotificationType;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public record NotificationDto(
    UUID publicId,
    NotificationType type,
    String title,
    String body,
    UUID recipePublicId,
    UUID logPostPublicId,
    String senderUsername,
    String senderProfileImageUrl,
    Boolean isRead,
    Instant createdAt,
    Map<String, Object> data
) {
    public static NotificationDto from(Notification n) {
        return new NotificationDto(
            n.getPublicId(),
            n.getType(),
            n.getTitle(),
            n.getBody(),
            n.getRecipe() != null ? n.getRecipe().getPublicId() : null,
            n.getLogPost() != null ? n.getLogPost().getPublicId() : null,
            n.getSender() != null ? n.getSender().getUsername() : null,
            n.getSender() != null ? n.getSender().getProfileImageUrl() : null,
            n.getIsRead(),
            n.getCreatedAt(),
            n.getData()
        );
    }
}
