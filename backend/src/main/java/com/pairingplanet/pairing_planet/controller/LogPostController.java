package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.common.CursorPageResponse;
import com.pairingplanet.pairing_planet.dto.common.UnifiedPageResponse;
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
     * 모든 로그 탐색 (Dual pagination: cursor + offset)
     * GET /api/v1/log_posts?cursor=xxx&size=10 (mobile)
     * GET /api/v1/log_posts?page=0&size=10 (web)
     * GET /api/v1/log_posts?q=검색어 : 제목/내용/레시피명 검색
     * GET /api/v1/log_posts?outcomes=PARTIAL,FAILED : outcome 필터링
     */
    @GetMapping
    public ResponseEntity<UnifiedPageResponse<LogPostSummaryDto>> getAllLogs(
            @RequestParam(name = "q", required = false) String searchKeyword,
            @RequestParam(name = "outcomes", required = false) String outcomes,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        // 검색어가 있으면 검색 모드
        if (searchKeyword != null && !searchKeyword.isBlank()) {
            return ResponseEntity.ok(logPostService.searchLogPostsUnified(searchKeyword, cursor, page, size));
        }
        // outcome 필터링
        java.util.List<String> outcomeList = null;
        if (outcomes != null && !outcomes.isBlank()) {
            outcomeList = java.util.Arrays.asList(outcomes.split(","));
        }
        return ResponseEntity.ok(logPostService.getAllLogsUnified(outcomeList, cursor, page, size));
    }

    /**
     * 내 로그 목록 조회 (마이페이지용, Dual pagination: cursor + offset)
     * GET /api/v1/log_posts/my?cursor=xxx&size=10&outcome=SUCCESS|PARTIAL|FAILED (mobile)
     * GET /api/v1/log_posts/my?page=0&size=10&outcome=SUCCESS|PARTIAL|FAILED (web)
     */
    @GetMapping("/my")
    public ResponseEntity<UnifiedPageResponse<LogPostSummaryDto>> getMyLogs(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(name = "outcome", required = false) String outcome,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        return ResponseEntity.ok(logPostService.getMyLogsUnified(principal.getId(), outcome, cursor, page, size));
    }

    /**
     * 특정 레시피에 달린 로그 목록 조회
     * GET /api/v1/log_posts/recipe/{recipePublicId}?page=0&size=20
     */
    @GetMapping("/recipe/{recipePublicId}")
    public ResponseEntity<Slice<LogPostSummaryDto>> getLogsByRecipe(
            @PathVariable("recipePublicId") UUID recipePublicId,
            Pageable pageable) {
        return ResponseEntity.ok(logPostService.getLogsByRecipe(recipePublicId, pageable));
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
     * 저장한 로그 목록 조회 (Dual pagination: cursor + offset)
     * GET /api/v1/log_posts/saved?cursor=xxx&size=20 (mobile)
     * GET /api/v1/log_posts/saved?page=0&size=20 (web)
     */
    @GetMapping("/saved")
    public ResponseEntity<UnifiedPageResponse<LogPostSummaryDto>> getSavedLogs(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        return ResponseEntity.ok(savedLogService.getSavedLogsUnified(principal.getId(), cursor, page, size));
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
