package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.dto.admin.SuggestedIngredientAdminDto;
import com.cookstemma.cookstemma.dto.admin.SuggestedIngredientFilterDto;
import com.cookstemma.cookstemma.service.AdminSuggestedIngredientService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Admin controller for managing user suggested ingredients.
 * All endpoints require ADMIN role.
 */
@RestController
@RequestMapping("/api/v1/admin/suggested-ingredients")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class SuggestedIngredientAdminController {

    private final AdminSuggestedIngredientService service;

    /**
     * Get paginated list of suggested ingredients with optional filters.
     *
     * GET /api/v1/admin/suggested-ingredients?page=0&size=20&ingredientType=MAIN&status=PENDING
     */
    @GetMapping
    public ResponseEntity<Page<SuggestedIngredientAdminDto>> getSuggestedIngredients(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String suggestedName,
            @RequestParam(required = false) IngredientType ingredientType,
            @RequestParam(required = false) String localeCode,
            @RequestParam(required = false) SuggestionStatus status,
            @RequestParam(required = false) String username,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortOrder
    ) {
        SuggestedIngredientFilterDto filter = new SuggestedIngredientFilterDto(
                suggestedName, ingredientType, localeCode, status, username, sortBy, sortOrder
        );
        return ResponseEntity.ok(service.getSuggestedIngredients(filter, page, size));
    }

    /**
     * Update the status of a suggested ingredient.
     *
     * PATCH /api/v1/admin/suggested-ingredients/{publicId}/status
     */
    @PatchMapping("/{publicId}/status")
    public ResponseEntity<SuggestedIngredientAdminDto> updateStatus(
            @PathVariable UUID publicId,
            @RequestBody StatusUpdateRequest request
    ) {
        return ResponseEntity.ok(service.updateStatus(publicId, request.status()));
    }

    public record StatusUpdateRequest(SuggestionStatus status) {}
}
