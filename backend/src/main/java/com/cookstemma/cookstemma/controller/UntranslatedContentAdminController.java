package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.admin.UntranslatedLogDto;
import com.cookstemma.cookstemma.dto.admin.UntranslatedRecipeDto;
import com.cookstemma.cookstemma.service.AdminUntranslatedContentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Admin controller for managing untranslated content.
 * All endpoints require ADMIN role.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class UntranslatedContentAdminController {

    private final AdminUntranslatedContentService service;

    /**
     * Get paginated list of untranslated recipes.
     *
     * GET /api/v1/admin/untranslated-recipes?page=0&size=20&title=...
     */
    @GetMapping("/untranslated-recipes")
    public ResponseEntity<Page<UntranslatedRecipeDto>> getUntranslatedRecipes(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String title,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortOrder
    ) {
        return ResponseEntity.ok(service.getUntranslatedRecipes(title, sortBy, sortOrder, page, size));
    }

    /**
     * Trigger re-translation for selected recipes.
     *
     * POST /api/v1/admin/untranslated-recipes/retranslate
     */
    @PostMapping("/untranslated-recipes/retranslate")
    public ResponseEntity<Map<String, Object>> retranslateRecipes(
            @RequestBody RetranslateRequest request
    ) {
        int count = service.triggerRecipeRetranslation(request.publicIds());

        log.info("Admin triggered re-translation for {} recipes", count);

        return ResponseEntity.ok(Map.of(
                "message", "Re-translation queued successfully",
                "recipesQueued", count
        ));
    }

    /**
     * Get paginated list of untranslated logs.
     *
     * GET /api/v1/admin/untranslated-logs?page=0&size=20&content=...
     */
    @GetMapping("/untranslated-logs")
    public ResponseEntity<Page<UntranslatedLogDto>> getUntranslatedLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String content,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortOrder
    ) {
        return ResponseEntity.ok(service.getUntranslatedLogs(content, sortBy, sortOrder, page, size));
    }

    /**
     * Trigger re-translation for selected logs.
     *
     * POST /api/v1/admin/untranslated-logs/retranslate
     */
    @PostMapping("/untranslated-logs/retranslate")
    public ResponseEntity<Map<String, Object>> retranslateLogs(
            @RequestBody RetranslateRequest request
    ) {
        int count = service.triggerLogRetranslation(request.publicIds());

        log.info("Admin triggered re-translation for {} logs", count);

        return ResponseEntity.ok(Map.of(
                "message", "Re-translation queued successfully",
                "logsQueued", count
        ));
    }

    public record RetranslateRequest(List<UUID> publicIds) {}
}
