package com.cookstemma.cookstemma.dto.bot;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/**
 * Request DTO for creating a new bot user (admin only).
 */
public record CreateBotUserRequestDto(
        @NotBlank(message = "Username is required")
        @Size(min = 3, max = 50, message = "Username must be 3-50 characters")
        @Pattern(regexp = "^[a-z0-9_]+$", message = "Username must be lowercase alphanumeric with underscores")
        String username,

        @NotNull(message = "Persona public ID is required")
        UUID personaPublicId,

        @Size(max = 255, message = "Profile image URL too long")
        String profileImageUrl,

        @Size(max = 150, message = "Bio must be 150 characters or less")
        String bio
) {}
