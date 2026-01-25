package com.cookstemma.cookstemma.dto.recipe;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record CreateRecipeRequestDto(
        @NotBlank(message = "제목은 필수입니다")
        @Size(min = 2, max = 200, message = "제목은 2자 이상 200자 이하여야 합니다")
        String title,
        @Size(max = 2000, message = "설명은 2000자 이하여야 합니다")
        String description,
        String cookingStyle,
        UUID food1MasterPublicId,
        @Size(max = 50, message = "요리명은 50자 이하여야 합니다")
        String newFoodName,
        @NotEmpty(message = "재료는 최소 1개 이상 필요합니다")
        List<IngredientDto> ingredients,
        @NotEmpty(message = "조리 단계는 최소 1개 이상 필요합니다")
        List<StepDto> steps,
        @NotEmpty(message = "완성 사진은 최소 1장 이상 필요합니다")
        List<UUID> imagePublicIds,
        String changeCategory,
        UUID parentPublicId,
        UUID rootPublicId,
        // Phase 7-3: Automatic Change Detection
        Map<String, Object> changeDiff,
        @Size(max = 2000, message = "변경 사유는 2000자 이하여야 합니다")
        String changeReason,
        // Hashtags (e.g., ["vegetarian", "quick-meal", "spicy"])
        List<String> hashtags,
        // Servings (default: 2)
        Integer servings,
        // Cooking time range (e.g., "UNDER_15_MIN", "MIN_15_TO_30", etc.)
        String cookingTimeRange,
        // Private visibility (default: false = public)
        Boolean isPrivate
) {}
