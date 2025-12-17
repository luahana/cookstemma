package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CreatePostRequestDto;
import com.pairingplanet.pairing_planet.dto.post.PostResponseDto;
import com.pairingplanet.pairing_planet.service.PostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    @PostMapping
    public ResponseEntity<PostResponseDto> createPost(
            @RequestHeader("X-User-Id") Long userId, // 실제로는 Security Context에서 가져옴
            @Valid @RequestBody CreatePostRequestDto request
    ) {
        PostResponseDto response = postService.createPost(userId, request);
        return ResponseEntity.ok(response);
    }
}