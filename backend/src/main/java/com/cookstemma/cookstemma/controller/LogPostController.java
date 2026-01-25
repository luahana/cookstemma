package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.common.CursorPageResponse;
import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import com.cookstemma.cookstemma.dto.log_post.*;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.LogPostService;
import com.cookstemma.cookstemma.service.SavedLogService;
import com.cookstemma.cookstemma.util.LocaleUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.context.i18n.LocaleContextHolder;
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
     * GET /api/v1/log_posts?minRating=1&maxRating=5 : rating 범위 필터링
     * GET /api/v1/log_posts?sort=recent|popular|trending : 정렬 옵션
     * GET /api/v1/log_posts?locale=KR : cooking style 필터링
     */
    @GetMapping
    public ResponseEntity<UnifiedPageResponse<LogPostSummaryDto>> getAllLogs(
            @RequestParam(name = "q", required = false) String searchKeyword,
            @RequestParam(name = "minRating", required = false) Integer minRating,
            @RequestParam(name = "maxRating", required = false) Integer maxRating,
            @RequestParam(name = "locale", required = false) String cookingStyle,
            @RequestParam(name = "sort", required = false) String sort,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        // Get content locale from Accept-Language header for translation
        String contentLocale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        // 검색어가 있으면 검색 모드
        if (searchKeyword != null && !searchKeyword.isBlank()) {
            return ResponseEntity.ok(logPostService.searchLogPostsUnified(searchKeyword, cursor, page, size, contentLocale));
        }
        return ResponseEntity.ok(logPostService.getAllLogsUnified(minRating, maxRating, cookingStyle, sort, cursor, page, size, contentLocale));
    }

    /**
     * 내 로그 목록 조회 (마이페이지용, Dual pagination: cursor + offset)
     * GET /api/v1/log_posts/my?cursor=xxx&size=10&minRating=1&maxRating=5 (mobile)
     * GET /api/v1/log_posts/my?page=0&size=10&minRating=1&maxRating=5 (web)
     */
    @GetMapping("/my")
    public ResponseEntity<UnifiedPageResponse<LogPostSummaryDto>> getMyLogs(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(name = "minRating", required = false) Integer minRating,
            @RequestParam(name = "maxRating", required = false) Integer maxRating,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(logPostService.getMyLogsUnified(principal.getId(), minRating, maxRating, cursor, page, size, locale));
    }

    /**
     * 특정 레시피에 달린 로그 목록 조회
     * GET /api/v1/log_posts/recipe/{recipePublicId}?page=0&size=20
     */
    @GetMapping("/recipe/{recipePublicId}")
    public ResponseEntity<Slice<LogPostSummaryDto>> getLogsByRecipe(
            @PathVariable("recipePublicId") UUID recipePublicId,
            Pageable pageable) {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(logPostService.getLogsByRecipe(recipePublicId, pageable, locale));
    }

    // --- [LOG DETAIL] ---
    /**
     * 로그 상세: 사진, 메모, 연결된 레시피 카드 포함
     * Locale resolved from Accept-Language header.
     */
    @GetMapping("/{publicId}")
    public ResponseEntity<LogPostDetailResponseDto> getLogDetail(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long userId = principal != null ? principal.getId() : null;
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(logPostService.getLogDetail(publicId, userId, locale));
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
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(savedLogService.getSavedLogsUnified(principal.getId(), cursor, page, size, locale));
    }

    /**
     * Check if log is saved by current user
     * GET /api/v1/log_posts/{publicId}/saved
     */
    @GetMapping("/{publicId}/saved")
    public ResponseEntity<java.util.Map<String, Boolean>> checkLogSaved(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        boolean isSaved = principal != null && savedLogService.isSavedByUserPublicId(publicId, principal.getId());
        return ResponseEntity.ok(java.util.Map.of("isSaved", isSaved));
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
