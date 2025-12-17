package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.SavedPostDto;
import com.pairingplanet.pairing_planet.service.SavedPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/saved-posts")
@RequiredArgsConstructor
public class SavedPostController {

    private final SavedPostService savedPostService;

    // 저장 토글
    @PostMapping("/{postId}")
    public ResponseEntity<Map<String, Boolean>> toggleSave(
            @AuthenticationPrincipal Long userId, // Security Context에서 ID 추출
            @PathVariable Long postId
    ) {
        boolean isSaved = savedPostService.toggleSave(userId, postId);
        return ResponseEntity.ok(Map.of("isSaved", isSaved));
    }

    // 저장 목록 조회 (무한 스크롤)
    @GetMapping
    public ResponseEntity<CursorResponse<SavedPostDto>> getMySavedPosts(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "10") int size
    ) {
        CursorResponse<SavedPostDto> response = savedPostService.getSavedPosts(userId, cursor, size);
        return ResponseEntity.ok(response);
    }
}