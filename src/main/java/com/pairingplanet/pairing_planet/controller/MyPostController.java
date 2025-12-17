package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.MyPostResponseDto;
import com.pairingplanet.pairing_planet.dto.post.PostUpdateRequestDto;
import com.pairingplanet.pairing_planet.service.MyPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class MyPostController {

    private final MyPostService myPostService;

    // [FR-160, FR-162] 내 포스트 목록 조회
    @GetMapping("/users/me/posts")
    public ResponseEntity<CursorResponse<MyPostResponseDto>> getMyPosts(
            @AuthenticationPrincipal Long userId, // Security Context에서 내 ID 추출
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "10") int size
    ) {
        CursorResponse<MyPostResponseDto> response = myPostService.getMyPosts(userId, cursor, size);
        return ResponseEntity.ok(response);
    }

    // [FR-161] 포스트 수정
    @PatchMapping("/posts/{postId}")
    public ResponseEntity<Void> updatePost(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long postId,
            @RequestBody PostUpdateRequestDto requestDto
    ) {
        myPostService.updatePost(userId, postId, requestDto);
        return ResponseEntity.ok().build();
    }

    // [FR-161] 포스트 삭제
    @DeleteMapping("/posts/{postId}")
    public ResponseEntity<Void> deletePost(
            @AuthenticationPrincipal Long userId,
            @PathVariable Long postId
    ) {
        myPostService.deletePost(userId, postId);
        return ResponseEntity.ok().build();
    }
}