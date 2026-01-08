package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.notification.*;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.NotificationService;
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
     * Send a test push notification to the current user (for testing only)
     */
    @PostMapping("/test")
    public ResponseEntity<String> sendTestNotification(
            @AuthenticationPrincipal UserPrincipal principal) {
        notificationService.sendTestNotification(principal);
        return ResponseEntity.ok("Test notification sent");
    }
}
