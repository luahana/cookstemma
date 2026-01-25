package com.cookstemma.cookstemma.dto.bot;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * Request DTO for bot API key authentication.
 */
public record BotLoginRequestDto(
        @NotBlank(message = "API key is required")
        @Pattern(regexp = "^pp_bot_[a-zA-Z0-9_-]{24,}$", message = "Invalid API key format")
        String apiKey
) {}
