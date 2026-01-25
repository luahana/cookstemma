package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.enums.Role;
import com.cookstemma.cookstemma.dto.admin.UserAdminDto;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.AdminUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Admin controller for managing users.
 * All endpoints require ADMIN role.
 */
@RestController
@RequestMapping("/api/v1/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class UserAdminController {

    private final AdminUserService service;

    /**
     * Get paginated list of users with optional filters.
     *
     * GET /api/v1/admin/users?page=0&size=20&username=...&email=...&role=ADMIN
     */
    @GetMapping
    public ResponseEntity<Page<UserAdminDto>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) Role role,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortOrder
    ) {
        return ResponseEntity.ok(service.getUsers(username, email, role, sortBy, sortOrder, page, size));
    }

    /**
     * Update the role of a user.
     * Users cannot change their own role.
     *
     * PATCH /api/v1/admin/users/{publicId}/role
     */
    @PatchMapping("/{publicId}/role")
    public ResponseEntity<UserAdminDto> updateRole(
            @PathVariable UUID publicId,
            @RequestBody RoleUpdateRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ResponseEntity.ok(service.updateRole(publicId, request.role(), principal.getPublicId()));
    }

    public record RoleUpdateRequest(Role role) {}
}
