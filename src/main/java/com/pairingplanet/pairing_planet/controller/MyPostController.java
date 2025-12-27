package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.CursorResponseTotalCount;
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
    @GetMapping("/me/posts")
    public ResponseEntity<CursorResponseTotalCount<MyPostResponseDto>> getMyPosts(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(defaultValue = "ALL") String type, // DAILY, REVIEW, RECIPE 필터
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ResponseEntity.ok(myPostService.getMyPosts(userId, type, cursor, size));
    }
}