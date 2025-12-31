package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CursorResponseTotalCount;
import com.pairingplanet.pairing_planet.dto.post.SavedPostDto;
import com.pairingplanet.pairing_planet.service.SavedPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/posts/saved") // [변경] 보안 설정을 타기 쉬운 경로로 변경
@RequiredArgsConstructor
public class SavedPostController {

    private final SavedPostService savedPostService;

    // 저장 토글 (경로: POST /api/v1/posts/saved/{postId})
    @PostMapping("/{postId}")
    public ResponseEntity<Map<String, Boolean>> toggleSave(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID postId
    ) {
        boolean isSaved = savedPostService.toggleSave(userId, postId);
        return ResponseEntity.ok(Map.of("isSaved", isSaved));
    }

    // 저장 목록 조회 (경로: GET /api/v1/posts/saved?limit=20)
    @GetMapping
    public ResponseEntity<CursorResponseTotalCount<SavedPostDto>> getMySavedPosts(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(required = false) String cursor,
            @RequestParam(name = "limit", defaultValue = "10") int limit // [변경] Flutter의 'limit' 파라미터와 매핑
    ) {
        // [참고] 기존 'size' 변수명을 Flutter에 맞춰 'limit'으로 처리
        CursorResponseTotalCount<SavedPostDto> response = savedPostService.getSavedPosts(userId, cursor, limit);
        return ResponseEntity.ok(response);
    }
}