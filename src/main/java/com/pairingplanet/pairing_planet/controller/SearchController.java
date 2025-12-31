package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.search.*;
import com.pairingplanet.pairing_planet.service.SearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/search")
@RequiredArgsConstructor
public class SearchController {

    private final SearchService searchService;

    @PostMapping("/posts")
    public ResponseEntity<SearchResponseDto> searchPosts(
            @AuthenticationPrincipal UUID userId, // [추가] 인증 정보 기반 히스토리 저장용
            @RequestBody PairingSearchRequestDto request) {
        return ResponseEntity.ok(searchService.searchPosts(userId, request));
    }

    /**
     * 내 검색 히스토리 조회
     */
    @GetMapping("/history")
    public ResponseEntity<List<SearchHistoryDto>> getMyHistory(@AuthenticationPrincipal UUID userId) {
        return ResponseEntity.ok(searchService.getMyHistory(userId));
    }

    /**
     * 검색 히스토리 개별 삭제
     */
    @DeleteMapping("/history/{historyId}")
    public ResponseEntity<Void> deleteHistory(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID historyId) {
        searchService.deleteHistory(userId, historyId);
        return ResponseEntity.noContent().build();
    }
}