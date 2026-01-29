package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.notification.*;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.NotificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    /**
     * Register FCM token for push notifications
     */
    @PostMapping("/fcm-token")
    public ResponseEntity<Void> registerFcmToken(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody RegisterFcmTokenRequest request) {
        notificationService.registerFcmToken(principal, request);
        return ResponseEntity.ok().build();
    }

    /**
     * Unregister FCM token (logout or disable notifications)
     */
    @DeleteMapping("/fcm-token")
    public ResponseEntity<Void> unregisterFcmToken(@RequestParam String token) {
        notificationService.unregisterFcmToken(token);
        return ResponseEntity.ok().build();
    }

    /**
     * Get notification inbox with pagination
     */
    @GetMapping
    public ResponseEntity<NotificationListResponse> getNotifications(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        NotificationListResponse response = notificationService
            .getNotifications(principal, PageRequest.of(page, size));
        return ResponseEntity.ok(response);
    }

    /**
     * Get unread notification count (for badge display)
     */
    @GetMapping("/unread-count")
    public ResponseEntity<UnreadCountResponse> getUnreadCount(
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(notificationService.getUnreadCount(principal));
    }

    /**
     * Mark single notification as read
     */
    @PatchMapping("/{notificationId}/read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable UUID notificationId,
            @AuthenticationPrincipal UserPrincipal principal) {
        notificationService.markAsRead(notificationId, principal);
        return ResponseEntity.ok().build();
    }

    /**
     * Mark all notifications as read
     */
    @PatchMapping("/read-all")
    public ResponseEntity<Void> markAllAsRead(
            @AuthenticationPrincipal UserPrincipal principal) {
        notificationService.markAllAsRead(principal);
        return ResponseEntity.ok().build();
    }

    /**
     * Delete a notification
     */
    @DeleteMapping("/{notificationId}")
    public ResponseEntity<Void> deleteNotification(
            @PathVariable UUID notificationId,
            @AuthenticationPrincipal UserPrincipal principal) {
        notificationService.deleteNotification(notificationId, principal);
        return ResponseEntity.noContent().build();
    }

    /**
     * Delete all notifications for the current user
     */
    @DeleteMapping
    public ResponseEntity<Void> deleteAllNotifications(
            @AuthenticationPrincipal UserPrincipal principal) {
        notificationService.deleteAllNotifications(principal);
        return ResponseEntity.noContent().build();
    }

    /**
     * Send a test push notification to the current user (for testing only)
     */
    @PostMapping("/test")
    public ResponseEntity<String> sendTestNotification(
            @AuthenticationPrincipal UserPrincipal principal) {
        notificationService.sendTestNotification(principal);
        return ResponseEntity.ok("Test notification sent");
    }
}
