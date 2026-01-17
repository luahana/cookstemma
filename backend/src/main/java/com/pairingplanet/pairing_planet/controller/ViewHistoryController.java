package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.ViewHistoryService;
import lombok.RequiredArgsConstructor;
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
        List<RecipeSummaryDto> recipes = viewHistoryService.getRecentlyViewedRecipes(
                principal.getId(),
                Math.min(limit, 50)
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
        List<LogPostSummaryDto> logs = viewHistoryService.getRecentlyViewedLogs(
                principal.getId(),
                Math.min(limit, 50)
        );
        return ResponseEntity.ok(logs);
    }
}
