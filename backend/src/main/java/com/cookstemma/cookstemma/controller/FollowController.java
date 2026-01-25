package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.follow.FollowListResponse;
import com.cookstemma.cookstemma.dto.follow.FollowStatusResponse;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.FollowService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class FollowController {

    private final FollowService followService;

    /**
     * Follow a user
     */
    @PostMapping("/{userId}/follow")
    public ResponseEntity<Void> follow(
            @PathVariable("userId") UUID targetUserId,
            @AuthenticationPrincipal UserPrincipal principal) {
        followService.follow(principal.getId(), targetUserId);
        return ResponseEntity.ok().build();
    }

    /**
     * Unfollow a user
     */
    @DeleteMapping("/{userId}/follow")
    public ResponseEntity<Void> unfollow(
            @PathVariable("userId") UUID targetUserId,
            @AuthenticationPrincipal UserPrincipal principal) {
        followService.unfollow(principal.getId(), targetUserId);
        return ResponseEntity.ok().build();
    }

    /**
     * Check if current user follows target user
     */
    @GetMapping("/{userId}/follow-status")
    public ResponseEntity<FollowStatusResponse> getFollowStatus(
            @PathVariable("userId") UUID targetUserId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long currentUserId = principal != null ? principal.getId() : null;
        FollowStatusResponse response = followService.getFollowStatus(currentUserId, targetUserId);
        return ResponseEntity.ok(response);
    }

    /**
     * Get followers of a user (people who follow them)
     */
    @GetMapping("/{userId}/followers")
    public ResponseEntity<FollowListResponse> getFollowers(
            @PathVariable("userId") UUID targetUserId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long currentUserId = principal != null ? principal.getId() : null;
        FollowListResponse response = followService.getFollowers(currentUserId, targetUserId, page, size);
        return ResponseEntity.ok(response);
    }

    /**
     * Get users that a user is following
     */
    @GetMapping("/{userId}/following")
    public ResponseEntity<FollowListResponse> getFollowing(
            @PathVariable("userId") UUID targetUserId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long currentUserId = principal != null ? principal.getId() : null;
        FollowListResponse response = followService.getFollowing(currentUserId, targetUserId, page, size);
        return ResponseEntity.ok(response);
    }
}
