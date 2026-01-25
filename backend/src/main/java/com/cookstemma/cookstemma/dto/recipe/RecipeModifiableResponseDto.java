package com.cookstemma.cookstemma.dto.recipe;

import lombok.Builder;

/**
 * Response DTO for checking if a recipe can be modified (edited/deleted).
 * A recipe can only be modified by its creator AND when it has no child variants or logs.
 */
@Builder
public record RecipeModifiableResponseDto(
        boolean canModify,
        boolean isOwner,
        boolean hasVariants,
        boolean hasLogs,
        long variantCount,
        long logCount,
        String reason  // null if canModify=true, otherwise explains why modification is blocked
) {}
