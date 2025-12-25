package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CreatePostRequestDto;
import com.pairingplanet.pairing_planet.dto.post.PostResponseDto;
import com.pairingplanet.pairing_planet.service.PostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID; // [필수]

@RestController
@RequestMapping("/api/v1/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    // ==========================================
    // 1. Create (타입별 분리)
    // ==========================================

    @PostMapping("/daily")
    public ResponseEntity<PostResponseDto> createDailyPost(
            @AuthenticationPrincipal UUID userId, // [변경] Long -> UUID
            @Valid @RequestBody CreatePostRequestDto request
    ) {
        return ResponseEntity.ok(postService.createDailyPost(userId, request));
    }

    @PostMapping("/reviews")
    public ResponseEntity<PostResponseDto> createReviewPost(
            @AuthenticationPrincipal UUID userId, // [변경]
            @Valid @RequestBody CreatePostRequestDto request
    ) {
        if (request.rating() == null) {
            throw new IllegalArgumentException("Rating is required for Review Post");
        }
        return ResponseEntity.ok(postService.createReviewPost(userId, request));
    }

    @PostMapping("/recipes")
    public ResponseEntity<PostResponseDto> createRecipePost(
            @AuthenticationPrincipal UUID userId, // [변경]
            @Valid @RequestBody CreatePostRequestDto request
    ) {
        return ResponseEntity.ok(postService.createRecipePost(userId, request));
    }

    // ==========================================
    // 2. Update & Delete (통합)
    // ==========================================

    @PatchMapping("/{postId}")
    public ResponseEntity<PostResponseDto> updatePost(
            @AuthenticationPrincipal UUID userId, // [변경]
            @PathVariable UUID postId,               // [변경] Long -> UUID
            @RequestBody CreatePostRequestDto request
    ) {
        return ResponseEntity.ok(postService.updatePost(userId, postId, request));
    }

    @DeleteMapping("/{postId}")
    public ResponseEntity<Void> deletePost(
            @AuthenticationPrincipal UUID userId, // [변경]
            @PathVariable UUID postId                // [변경]
    ) {
        postService.deletePost(userId, postId);
        return ResponseEntity.ok().build();
    }
}