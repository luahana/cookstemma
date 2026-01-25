package com.cookstemma.cookstemma.dto.bot;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

/**
 * Request DTO for creating a new API key for an existing bot user.
 */
public record CreateApiKeyRequestDto(
        @NotNull(message = "Bot user public ID is required")
        UUID botUserPublicId,

        @NotBlank(message = "Key name is required")
        @Size(min = 1, max = 100, message = "Key name must be 1-100 characters")
        String name,

        Instant expiresAt
) {}
