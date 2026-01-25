package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.admin.AdminCommentDto;
import com.cookstemma.cookstemma.dto.admin.AdminLogPostDto;
import com.cookstemma.cookstemma.dto.admin.AdminRecipeDto;
import com.cookstemma.cookstemma.service.AdminContentService;
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
 * Admin controller for managing all content (recipes, logs, comments).
 * All endpoints require ADMIN role.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class ContentAdminController {

    private final AdminContentService adminContentService;

    // ==================== RECIPES ====================

    /**
     * Get paginated list of all recipes for admin management.
     *
     * GET /api/v1/admin/recipes?page=0&size=20&title=...&username=...
     */
    @GetMapping("/recipes")
    public ResponseEntity<Page<AdminRecipeDto>> getRecipes(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String username
    ) {
        return ResponseEntity.ok(adminContentService.getRecipes(title, username, page, size));
    }

    /**
     * Delete multiple recipes (bypasses owner check and variant/log restrictions).
     *
     * POST /api/v1/admin/recipes/delete
     * Body: { "publicIds": ["uuid1", "uuid2", ...] }
     */
    @PostMapping("/recipes/delete")
    public ResponseEntity<Map<String, Object>> deleteRecipes(
            @RequestBody DeleteRequest request
    ) {
        int deletedCount = adminContentService.deleteRecipes(request.publicIds());
        log.info("Admin deleted {} recipes", deletedCount);

        return ResponseEntity.ok(Map.of(
                "message", "Recipes deleted successfully",
                "deletedCount", deletedCount
        ));
    }

    // ==================== LOG POSTS ====================

    /**
     * Get paginated list of all log posts for admin management.
     *
     * GET /api/v1/admin/logs?page=0&size=20&content=...&username=...
     */
    @GetMapping("/logs")
    public ResponseEntity<Page<AdminLogPostDto>> getLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String content,
            @RequestParam(required = false) String username
    ) {
        return ResponseEntity.ok(adminContentService.getLogs(content, username, page, size));
    }

    /**
     * Delete multiple log posts (bypasses owner check).
     *
     * POST /api/v1/admin/logs/delete
     * Body: { "publicIds": ["uuid1", "uuid2", ...] }
     */
    @PostMapping("/logs/delete")
    public ResponseEntity<Map<String, Object>> deleteLogs(
            @RequestBody DeleteRequest request
    ) {
        int deletedCount = adminContentService.deleteLogs(request.publicIds());
        log.info("Admin deleted {} log posts", deletedCount);

        return ResponseEntity.ok(Map.of(
                "message", "Log posts deleted successfully",
                "deletedCount", deletedCount
        ));
    }

    // ==================== COMMENTS ====================

    /**
     * Get paginated list of all comments for admin management.
     *
     * GET /api/v1/admin/comments?page=0&size=20&content=...&username=...
     */
    @GetMapping("/comments")
    public ResponseEntity<Page<AdminCommentDto>> getComments(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String content,
            @RequestParam(required = false) String username
    ) {
        return ResponseEntity.ok(adminContentService.getComments(content, username, page, size));
    }

    /**
     * Delete multiple comments (bypasses owner check, adjusts counts).
     *
     * POST /api/v1/admin/comments/delete
     * Body: { "publicIds": ["uuid1", "uuid2", ...] }
     */
    @PostMapping("/comments/delete")
    public ResponseEntity<Map<String, Object>> deleteComments(
            @RequestBody DeleteRequest request
    ) {
        int deletedCount = adminContentService.deleteComments(request.publicIds());
        log.info("Admin deleted {} comments", deletedCount);

        return ResponseEntity.ok(Map.of(
                "message", "Comments deleted successfully",
                "deletedCount", deletedCount
        ));
    }

    // ==================== REQUEST DTOs ====================

    public record DeleteRequest(List<UUID> publicIds) {}
}
