package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.dto.admin.SuggestedFoodFilterDto;
import com.cookstemma.cookstemma.dto.admin.UserSuggestedFoodDto;
import com.cookstemma.cookstemma.service.AdminSuggestedFoodService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Admin controller for managing user suggested foods.
 * All endpoints require ADMIN role.
 */
@RestController
@RequestMapping("/api/v1/admin/suggested-foods")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class SuggestedFoodAdminController {

    private final AdminSuggestedFoodService service;

    /**
     * Get paginated list of suggested foods with optional filters.
     *
     * GET /api/v1/admin/suggested-foods?page=0&size=20&suggestedName=...&status=PENDING&...
     */
    @GetMapping
    public ResponseEntity<Page<UserSuggestedFoodDto>> getSuggestedFoods(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String suggestedName,
            @RequestParam(required = false) String localeCode,
            @RequestParam(required = false) SuggestionStatus status,
            @RequestParam(required = false) String username,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortOrder
    ) {
        SuggestedFoodFilterDto filter = new SuggestedFoodFilterDto(
                suggestedName, localeCode, status, username, sortBy, sortOrder
        );
        return ResponseEntity.ok(service.getSuggestedFoods(filter, page, size));
    }

    /**
     * Update the status of a suggested food.
     *
     * PATCH /api/v1/admin/suggested-foods/{publicId}/status
     */
    @PatchMapping("/{publicId}/status")
    public ResponseEntity<UserSuggestedFoodDto> updateStatus(
            @PathVariable UUID publicId,
            @RequestBody StatusUpdateRequest request
    ) {
        return ResponseEntity.ok(service.updateStatus(publicId, request.status()));
    }

    public record StatusUpdateRequest(SuggestionStatus status) {}
}
