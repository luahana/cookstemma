package com.cookstemma.cookstemma.dto.recipe;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

/**
 * Request DTO for updating an existing recipe.
 * Only the recipe creator can update, and only if there are no child variants or logs.
 */
public record UpdateRecipeRequestDto(
        @NotBlank(message = "제목은 필수입니다")
        @Size(min = 2, message = "제목은 최소 2자 이상이어야 합니다")
        String title,
        String description,
        String cookingStyle,
        @NotEmpty(message = "재료는 최소 1개 이상 필요합니다")
        List<IngredientDto> ingredients,
        @NotEmpty(message = "조리 단계는 최소 1개 이상 필요합니다")
        List<StepDto> steps,
        @NotEmpty(message = "완성 사진은 최소 1장 이상 필요합니다")
        List<UUID> imagePublicIds,
        List<String> hashtags,
        // Servings (default: 2)
        Integer servings,
        // Cooking time range (e.g., "UNDER_15_MIN", "MIN_15_TO_30", etc.)
        String cookingTimeRange,
        // Private visibility (null = no change, true/false = update)
        Boolean isPrivate
) {}
