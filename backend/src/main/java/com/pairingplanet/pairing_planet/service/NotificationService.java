package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.notification.Notification;
import com.pairingplanet.pairing_planet.domain.entity.notification.UserFcmToken;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.NotificationType;
import com.pairingplanet.pairing_planet.dto.notification.*;
import com.pairingplanet.pairing_planet.repository.notification.NotificationRepository;
import com.pairingplanet.pairing_planet.repository.notification.UserFcmTokenRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserFcmTokenRepository fcmTokenRepository;
    private final UserRepository userRepository;
    private final PushNotificationService pushNotificationService;

    // =========== FCM Token Management ===========

    public void registerFcmToken(UserPrincipal principal, RegisterFcmTokenRequest request) {
        User user = userRepository.getReferenceById(principal.getId());

        // Check if token already exists for this user
        fcmTokenRepository.findByUserIdAndFcmToken(principal.getId(), request.fcmToken())
            .ifPresentOrElse(
                existingToken -> {
                    // Update existing token
                    existingToken.setIsActive(true);
                    existingToken.setLastUsedAt(Instant.now());
                    existingToken.setDeviceType(request.deviceType());
                    if (request.deviceId() != null) {
                        existingToken.setDeviceId(request.deviceId());
                    }
                    log.debug("Updated existing FCM token for user {}", principal.getId());
                },
                () -> {
                    // Check if token exists for different user (device changed hands)
                    fcmTokenRepository.findByFcmToken(request.fcmToken())
                        .ifPresent(fcmTokenRepository::delete);

                    // Create new token
                    UserFcmToken newToken = UserFcmToken.builder()
                        .user(user)
                        .fcmToken(request.fcmToken())
                        .deviceType(request.deviceType())
                        .deviceId(request.deviceId())
                        .isActive(true)
                        .lastUsedAt(Instant.now())
                        .build();
                    fcmTokenRepository.save(newToken);
                    log.debug("Registered new FCM token for user {}", principal.getId());
                }
            );
    }

    public void unregisterFcmToken(String fcmToken) {
        fcmTokenRepository.deleteByFcmToken(fcmToken);
        log.debug("Unregistered FCM token");
    }

    // =========== Notification Creation & Sending ===========

    /**
     * Called when someone creates a log post (cooks a recipe)
     */
    public void notifyRecipeCooked(Recipe recipe, LogPost logPost, User sender) {
        Long recipeOwnerId = recipe.getCreatorId();

        // Don't notify yourself
        if (recipeOwnerId.equals(sender.getId())) {
            log.debug("Skipping self-notification for RECIPE_COOKED");
            return;
        }

        User recipient = userRepository.getReferenceById(recipeOwnerId);

        String title = "누군가 당신의 레시피를 요리했어요!";
        String body = String.format("%s님이 '%s' 레시피를 요리하고 후기를 남겼습니다.",
            sender.getUsername(), truncate(recipe.getTitle(), 30));

        Notification notification = Notification.builder()
            .recipient(recipient)
            .sender(sender)
            .type(NotificationType.RECIPE_COOKED)
            .recipe(recipe)
            .logPost(logPost)
            .title(title)
            .body(body)
            .data(Map.of(
                "recipeTitle", recipe.getTitle(),
                "senderName", sender.getUsername()
            ))
            .build();

        notificationRepository.save(notification);
        pushNotificationService.sendToUser(recipeOwnerId, notification);
        log.info("Sent RECIPE_COOKED notification to user {} from user {}", recipeOwnerId, sender.getId());
    }

    /**
     * Called when someone follows a user
     */
    public void notifyNewFollower(User followedUser, User follower) {
        Long recipientId = followedUser.getId();

        // Don't notify yourself (shouldn't happen but safety check)
        if (recipientId.equals(follower.getId())) {
            log.debug("Skipping self-notification for NEW_FOLLOWER");
            return;
        }

        String title = "새로운 팔로워가 생겼어요!";
        String body = String.format("%s님이 회원님을 팔로우하기 시작했습니다.",
            follower.getUsername());

        Notification notification = Notification.builder()
            .recipient(followedUser)
            .sender(follower)
            .type(NotificationType.NEW_FOLLOWER)
            .title(title)
            .body(body)
            .data(Map.of(
                "followerName", follower.getUsername(),
                "followerPublicId", follower.getPublicId().toString()
            ))
            .build();

        notificationRepository.save(notification);
        pushNotificationService.sendToUser(recipientId, notification);
        log.info("Sent NEW_FOLLOWER notification to user {} from user {}", recipientId, follower.getId());
    }

    /**
     * Called when someone creates a variation of a recipe
     */
    public void notifyRecipeVariation(Recipe parentRecipe, Recipe newVariation, User sender) {
        Long parentOwnerId = parentRecipe.getCreatorId();

        // Don't notify yourself
        if (parentOwnerId.equals(sender.getId())) {
            log.debug("Skipping self-notification for RECIPE_VARIATION");
            return;
        }

        User recipient = userRepository.getReferenceById(parentOwnerId);

        String title = "당신의 레시피에 새로운 변형이 생겼어요!";
        String body = String.format("%s님이 '%s' 레시피를 변형하여 '%s'를 만들었습니다.",
            sender.getUsername(),
            truncate(parentRecipe.getTitle(), 20),
            truncate(newVariation.getTitle(), 20));

        Notification notification = Notification.builder()
            .recipient(recipient)
            .sender(sender)
            .type(NotificationType.RECIPE_VARIATION)
            .recipe(newVariation)
            .title(title)
            .body(body)
            .data(Map.of(
                "parentRecipeTitle", parentRecipe.getTitle(),
                "newRecipeTitle", newVariation.getTitle(),
                "senderName", sender.getUsername()
            ))
            .build();

        notificationRepository.save(notification);
        pushNotificationService.sendToUser(parentOwnerId, notification);
        log.info("Sent RECIPE_VARIATION notification to user {} from user {}", parentOwnerId, sender.getId());
    }

    // =========== Notification Inbox ===========

    @Transactional(readOnly = true)
    public NotificationListResponse getNotifications(UserPrincipal principal, Pageable pageable) {
        Slice<Notification> slice = notificationRepository
            .findByRecipientIdOrderByCreatedAtDesc(principal.getId(), pageable);

        long unreadCount = notificationRepository.countUnreadByRecipientId(principal.getId());

        return new NotificationListResponse(
            slice.getContent().stream().map(NotificationDto::from).toList(),
            unreadCount,
            slice.hasNext()
        );
    }

    @Transactional(readOnly = true)
    public UnreadCountResponse getUnreadCount(UserPrincipal principal) {
        long count = notificationRepository.countUnreadByRecipientId(principal.getId());
        return new UnreadCountResponse(count);
    }

    public void markAsRead(UUID notificationPublicId, UserPrincipal principal) {
        Notification notification = notificationRepository.findByPublicId(notificationPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Notification not found"));

        // Security check
        if (!notification.getRecipient().getId().equals(principal.getId())) {
            throw new SecurityException("Not authorized to mark this notification as read");
        }

        notification.markAsRead();
        log.debug("Marked notification {} as read", notificationPublicId);
    }

    public void markAllAsRead(UserPrincipal principal) {
        notificationRepository.markAllAsReadByRecipientId(principal.getId());
        log.debug("Marked all notifications as read for user {}", principal.getId());
    }

    // =========== Test ===========

    /**
     * Send a test notification to the current user (for testing push notifications)
     */
    public void sendTestNotification(UserPrincipal principal) {
        User user = userRepository.getReferenceById(principal.getId());

        String title = "테스트 알림";
        String body = "푸시 알림이 정상적으로 작동합니다!";

        Notification notification = Notification.builder()
            .recipient(user)
            .sender(user)
            .type(NotificationType.RECIPE_COOKED)
            .title(title)
            .body(body)
            .data(Map.of("test", "true"))
            .build();

        notificationRepository.save(notification);
        pushNotificationService.sendToUser(principal.getId(), notification);
        log.info("Sent TEST notification to user {}", principal.getId());
    }

    // =========== Helpers ===========

    private String truncate(String text, int maxLength) {
        if (text == null) return "";
        if (text.length() <= maxLength) return text;
        return text.substring(0, maxLength - 3) + "...";
    }
}
