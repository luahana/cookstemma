package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.bot.*;
import com.cookstemma.cookstemma.service.BotPersonaService;
import com.cookstemma.cookstemma.service.BotUserService;
import com.cookstemma.cookstemma.service.ImageProcessingService;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Admin controller for managing bot users and personas.
 * All endpoints require ADMIN role.
 */
@RestController
@RequestMapping("/api/v1/admin/bots")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class BotAdminController {

    private final BotUserService botUserService;
    private final BotPersonaService botPersonaService;
    private final ImageProcessingService imageProcessingService;
    private final ImageRepository imageRepository;

    // ==================== Bot Users ====================

    /**
     * Gets all bot users.
     *
     * GET /api/v1/admin/bots/users
     */
    @GetMapping("/users")
    public ResponseEntity<List<BotUserDto>> getAllBotUsers() {
        return ResponseEntity.ok(botUserService.getAllBotUsersDto());
    }

    /**
     * Creates a new bot user with an initial API key.
     * The API key is only returned in this response and cannot be retrieved later.
     *
     * POST /api/v1/admin/bots/users
     */
    @PostMapping("/users")
    public ResponseEntity<CreateBotUserResponseDto> createBotUser(
            @RequestBody @Valid CreateBotUserRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(botUserService.createBotUser(request));
    }

    /**
     * Creates a new API key for an existing bot user.
     *
     * POST /api/v1/admin/bots/api-keys
     */
    @PostMapping("/api-keys")
    public ResponseEntity<CreateApiKeyResponseDto> createApiKey(
            @RequestBody @Valid CreateApiKeyRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(botUserService.createApiKey(request));
    }

    /**
     * Gets all API keys for a bot user.
     *
     * GET /api/v1/admin/bots/users/{publicId}/api-keys
     */
    @GetMapping("/users/{publicId}/api-keys")
    public ResponseEntity<List<BotApiKeyDto>> getApiKeys(
            @PathVariable UUID publicId) {
        return ResponseEntity.ok(botUserService.getApiKeysForBot(publicId));
    }

    /**
     * Revokes (deactivates) an API key.
     *
     * DELETE /api/v1/admin/bots/api-keys/{publicId}
     */
    @DeleteMapping("/api-keys/{publicId}")
    public ResponseEntity<Void> revokeApiKey(@PathVariable UUID publicId) {
        botUserService.revokeApiKey(publicId);
        return ResponseEntity.noContent().build();
    }

    // ==================== Personas ====================

    /**
     * Gets all personas.
     *
     * GET /api/v1/admin/bots/personas
     */
    @GetMapping("/personas")
    public ResponseEntity<List<BotPersonaDto>> getAllPersonas() {
        return ResponseEntity.ok(botPersonaService.getAllPersonas());
    }

    /**
     * Gets a persona by public ID.
     *
     * GET /api/v1/admin/bots/personas/{publicId}
     */
    @GetMapping("/personas/{publicId}")
    public ResponseEntity<BotPersonaDto> getPersona(@PathVariable UUID publicId) {
        return ResponseEntity.ok(botPersonaService.getPersona(publicId));
    }

    /**
     * Activates a persona.
     *
     * POST /api/v1/admin/bots/personas/{publicId}/activate
     */
    @PostMapping("/personas/{publicId}/activate")
    public ResponseEntity<Void> activatePersona(@PathVariable UUID publicId) {
        botPersonaService.setPersonaActive(publicId, true);
        return ResponseEntity.ok().build();
    }

    /**
     * Deactivates a persona.
     *
     * POST /api/v1/admin/bots/personas/{publicId}/deactivate
     */
    @PostMapping("/personas/{publicId}/deactivate")
    public ResponseEntity<Void> deactivatePersona(@PathVariable UUID publicId) {
        botPersonaService.setPersonaActive(publicId, false);
        return ResponseEntity.ok().build();
    }

    // ==================== Image Variants (Debug) ====================

    /**
     * Manually trigger variant generation for an image (synchronous, for debugging).
     * This bypasses the async mechanism to test if processing logic works.
     *
     * POST /api/v1/admin/bots/images/{publicId}/generate-variants
     */
    @PostMapping("/images/{publicId}/generate-variants")
    public ResponseEntity<String> generateImageVariants(@PathVariable UUID publicId) {
        Image image = imageRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Image not found: " + publicId));

        try {
            // Call synchronously (not the async version) for debugging
            String result = imageProcessingService.generateVariantsSyncWithResult(image.getId());
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error: " + e.getMessage());
        }
    }
}
