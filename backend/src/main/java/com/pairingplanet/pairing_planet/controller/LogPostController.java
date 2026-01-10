package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.log_post.*;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.LogPostService;
import com.pairingplanet.pairing_planet.service.SavedLogService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/log_posts")
@RequiredArgsConstructor
public class LogPostController {

    private final LogPostService logPostService;
    private final SavedLogService savedLogService;

    /**
     * 새 로그 등록: 레시피를 만들어 본 경험 기록
     */
    @PostMapping
    public ResponseEntity<LogPostDetailResponseDto> createLog(
            @Valid @RequestBody CreateLogRequestDto req,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(logPostService.createLog(req, principal));
    }
    /**
     * 모든 로그 탐색 (무한 스크롤용 커서 기반 조회)
     * GET /api/v1/log_posts?page=0&size=10
     * GET /api/v1/log_posts?q=검색어 : 제목/내용/레시피명 검색
     */
    @GetMapping
    public ResponseEntity<Slice<LogPostSummaryDto>> getAllLogs(
            @RequestParam(name = "q", required = false) String searchKeyword,
            Pageable pageable) {
        // 검색어가 있으면 검색 모드
        if (searchKeyword != null && !searchKeyword.isBlank()) {
            return ResponseEntity.ok(logPostService.searchLogPosts(searchKeyword, pageable));
        }
        return ResponseEntity.ok(logPostService.getAllLogs(pageable));
    }

    /**
     * 내 로그 목록 조회 (마이페이지용)
     * GET /api/v1/log_posts/my?page=0&size=10&outcome=SUCCESS|PARTIAL|FAILED
     */
    @GetMapping("/my")
    public ResponseEntity<Slice<LogPostSummaryDto>> getMyLogs(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(name = "outcome", required = false) String outcome,
            Pageable pageable) {
        return ResponseEntity.ok(logPostService.getMyLogs(principal.getId(), outcome, pageable));
    }

    // --- [LOG DETAIL] ---
    /**
     * 로그 상세: 사진, 메모, 연결된 레시피 카드 포함
     */
    @GetMapping("/{publicId}")
    public ResponseEntity<LogPostDetailResponseDto> getLogDetail(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long userId = principal != null ? principal.getId() : null;
        return ResponseEntity.ok(logPostService.getLogDetail(publicId, userId));
    }

    /**
     * 로그 수정 (본인 로그만 수정 가능)
     * PUT /api/v1/log_posts/{publicId}
     */
    @PutMapping("/{publicId}")
    public ResponseEntity<LogPostDetailResponseDto> updateLog(
            @PathVariable("publicId") UUID publicId,
            @Valid @RequestBody UpdateLogRequestDto request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(logPostService.updateLog(publicId, request, principal.getId()));
    }

    /**
     * 로그 삭제 (본인 로그만 삭제 가능, 소프트 삭제)
     * DELETE /api/v1/log_posts/{publicId}
     */
    @DeleteMapping("/{publicId}")
    public ResponseEntity<Void> deleteLog(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        logPostService.deleteLog(publicId, principal.getId());
        return ResponseEntity.noContent().build();
    }

    // --- [SAVED LOGS (BOOKMARKS)] ---

    /**
     * 저장한 로그 목록 조회
     * GET /api/v1/log_posts/saved?page=0&size=20
     */
    @GetMapping("/saved")
    public ResponseEntity<Slice<LogPostSummaryDto>> getSavedLogs(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable) {
        return ResponseEntity.ok(savedLogService.getSavedLogs(principal.getId(), pageable));
    }

    /**
     * 로그 저장 (북마크)
     * POST /api/v1/log_posts/{publicId}/save
     */
    @PostMapping("/{publicId}/save")
    public ResponseEntity<Void> saveLog(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        savedLogService.saveLog(publicId, principal.getId());
        return ResponseEntity.ok().build();
    }

    /**
     * 로그 저장 취소
     * DELETE /api/v1/log_posts/{publicId}/save
     */
    @DeleteMapping("/{publicId}/save")
    public ResponseEntity<Void> unsaveLog(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        savedLogService.unsaveLog(publicId, principal.getId());
        return ResponseEntity.ok().build();
    }
}
