package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.dto.search.SearchHistoryRequest;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.SearchHistoryService;
import com.cookstemma.cookstemma.service.ViewHistoryService;
import com.cookstemma.cookstemma.util.LocaleUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/view-history")
@RequiredArgsConstructor
public class ViewHistoryController {

    private final ViewHistoryService viewHistoryService;
    private final SearchHistoryService searchHistoryService;

    /**
     * Record a recipe view.
     * POST /api/v1/view-history/recipes/{publicId}
     */
    @PostMapping("/recipes/{publicId}")
    public ResponseEntity<Void> recordRecipeView(
            @PathVariable UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        viewHistoryService.recordRecipeView(publicId, principal.getId());
        return ResponseEntity.ok().build();
    }

    /**
     * Record a log view.
     * POST /api/v1/view-history/logs/{publicId}
     */
    @PostMapping("/logs/{publicId}")
    public ResponseEntity<Void> recordLogView(
            @PathVariable UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        viewHistoryService.recordLogView(publicId, principal.getId());
        return ResponseEntity.ok().build();
    }

    /**
     * Get recently viewed recipes.
     * GET /api/v1/view-history/recipes?limit=10
     */
    @GetMapping("/recipes")
    public ResponseEntity<List<RecipeSummaryDto>> getRecentlyViewedRecipes(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "10") int limit) {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        List<RecipeSummaryDto> recipes = viewHistoryService.getRecentlyViewedRecipes(
                principal.getId(),
                Math.min(limit, 50),
                locale
        );
        return ResponseEntity.ok(recipes);
    }

    /**
     * Get recently viewed logs.
     * GET /api/v1/view-history/logs?limit=10
     */
    @GetMapping("/logs")
    public ResponseEntity<List<LogPostSummaryDto>> getRecentlyViewedLogs(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "10") int limit) {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        List<LogPostSummaryDto> logs = viewHistoryService.getRecentlyViewedLogs(
                principal.getId(),
                Math.min(limit, 50),
                locale
        );
        return ResponseEntity.ok(logs);
    }

    /**
     * Record a search query.
     * POST /api/v1/view-history/search
     */
    @PostMapping("/search")
    public ResponseEntity<Void> recordSearchHistory(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody SearchHistoryRequest request) {
        searchHistoryService.recordSearch(principal.getId(), request.query());
        return ResponseEntity.ok().build();
    }
}
