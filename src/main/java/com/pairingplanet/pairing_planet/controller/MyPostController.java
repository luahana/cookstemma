package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.MyPostResponseDto;
import com.pairingplanet.pairing_planet.service.MyPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID; // [필수]

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class MyPostController {

    private final MyPostService myPostService;

    // [FR-160, FR-162] 내 포스트 목록 조회
    @GetMapping("/users/me/posts")
    public ResponseEntity<CursorResponse<MyPostResponseDto>> getMyPosts(
            @AuthenticationPrincipal UUID userId, // [변경] Long -> UUID
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "10") int size
    ) {
        // Service 계층의 메서드 파라미터도 UUID로 변경해야 함
        CursorResponse<MyPostResponseDto> response = myPostService.getMyPosts(userId, cursor, size);
        return ResponseEntity.ok(response);
    }
}