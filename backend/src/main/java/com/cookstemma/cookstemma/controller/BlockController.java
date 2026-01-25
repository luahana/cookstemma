package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.block.BlockStatusResponse;
import com.cookstemma.cookstemma.dto.block.BlockedUsersListResponse;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.BlockService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class BlockController {

    private final BlockService blockService;

    /**
     * Block a user
     */
    @PostMapping("/{userId}/block")
    public ResponseEntity<Void> blockUser(
            @PathVariable("userId") UUID targetUserId,
            @AuthenticationPrincipal UserPrincipal principal) {
        blockService.blockUser(principal.getId(), targetUserId);
        return ResponseEntity.ok().build();
    }

    /**
     * Unblock a user
     */
    @DeleteMapping("/{userId}/block")
    public ResponseEntity<Void> unblockUser(
            @PathVariable("userId") UUID targetUserId,
            @AuthenticationPrincipal UserPrincipal principal) {
        blockService.unblockUser(principal.getId(), targetUserId);
        return ResponseEntity.ok().build();
    }

    /**
     * Get block status between current user and target user
     */
    @GetMapping("/{userId}/block-status")
    public ResponseEntity<BlockStatusResponse> getBlockStatus(
            @PathVariable("userId") UUID targetUserId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long currentUserId = principal != null ? principal.getId() : null;
        BlockStatusResponse response = blockService.getBlockStatus(currentUserId, targetUserId);
        return ResponseEntity.ok(response);
    }

    /**
     * Get list of blocked users for current user
     */
    @GetMapping("/me/blocked")
    public ResponseEntity<BlockedUsersListResponse> getBlockedUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        BlockedUsersListResponse response = blockService.getBlockedUsers(principal.getId(), page, size);
        return ResponseEntity.ok(response);
    }
}
