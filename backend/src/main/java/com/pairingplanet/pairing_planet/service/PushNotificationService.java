package com.pairingplanet.pairing_planet.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.*;
import com.pairingplanet.pairing_planet.domain.entity.notification.Notification;
import com.pairingplanet.pairing_planet.domain.entity.notification.UserFcmToken;
import com.pairingplanet.pairing_planet.repository.notification.UserFcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class PushNotificationService {

    private final UserFcmTokenRepository fcmTokenRepository;

    /**
     * Send push notification to all active devices of a user.
     * Runs asynchronously to avoid blocking the main thread.
     */
    @Async
    public void sendToUser(Long userId, Notification notification) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.warn("Firebase not initialized, skipping push notification");
            return;
        }

        List<UserFcmToken> tokens = fcmTokenRepository.findByUserIdAndIsActiveTrue(userId);
        if (tokens.isEmpty()) {
            log.debug("No active FCM tokens found for user {}", userId);
            return;
        }

        List<String> tokenStrings = tokens.stream()
            .map(UserFcmToken::getFcmToken)
            .toList();

        // Build data payload for navigation
        Map<String, String> data = buildDataPayload(notification);

        MulticastMessage message = MulticastMessage.builder()
            .setNotification(com.google.firebase.messaging.Notification.builder()
                .setTitle(notification.getTitle())
                .setBody(notification.getBody())
                .build())
            .putAllData(data)
            .setAndroidConfig(AndroidConfig.builder()
                .setNotification(AndroidNotification.builder()
                    .setClickAction("FLUTTER_NOTIFICATION_CLICK")
                    .build())
                .setPriority(AndroidConfig.Priority.HIGH)
                .build())
            .setApnsConfig(ApnsConfig.builder()
                .setAps(Aps.builder()
                    .setSound("default")
                    .setBadge(1)
                    .build())
                .build())
            .addAllTokens(tokenStrings)
            .build();

        try {
            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            log.info("Push notification sent: {} success, {} failure",
                response.getSuccessCount(), response.getFailureCount());

            // Handle failed tokens (deactivate invalid ones)
            handleFailedTokens(tokens, response);
        } catch (FirebaseMessagingException e) {
            log.error("Failed to send push notification: {}", e.getMessage());
        }
    }

    private Map<String, String> buildDataPayload(Notification notification) {
        Map<String, String> data = new HashMap<>();
        data.put("notificationType", notification.getType().name());
        data.put("notificationId", notification.getPublicId().toString());

        if (notification.getRecipe() != null) {
            data.put("recipeId", notification.getRecipe().getPublicId().toString());
        }
        if (notification.getLogPost() != null) {
            data.put("logPostId", notification.getLogPost().getPublicId().toString());
        }

        return data;
    }

    private void handleFailedTokens(List<UserFcmToken> tokens, BatchResponse response) {
        List<SendResponse> responses = response.getResponses();
        for (int i = 0; i < responses.size(); i++) {
            if (!responses.get(i).isSuccessful()) {
                FirebaseMessagingException exception = responses.get(i).getException();
                if (exception != null && isTokenInvalid(exception)) {
                    String invalidToken = tokens.get(i).getFcmToken();
                    log.info("Deactivating invalid FCM token: {}...", invalidToken.substring(0, Math.min(20, invalidToken.length())));
                    fcmTokenRepository.deactivateToken(invalidToken);
                }
            }
        }
    }

    private boolean isTokenInvalid(FirebaseMessagingException e) {
        return e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED
            || e.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT;
    }
}
