package com.pairingplanet.pairing_planet.dto.recipe;

import com.pairingplanet.pairing_planet.domain.enums.RecipeDifficulty;
import com.pairingplanet.pairing_planet.dto.food.FoodRequestDto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record CreateRecipeRequestDto(
        @NotBlank(message = "제목은 필수입니다")
        @Size(min = 2, message = "제목은 최소 2자 이상이어야 합니다")
        String title,
        String description,
        String culinaryLocale,
        UUID food1MasterPublicId,
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
        String changeReason,
        // Hashtags (e.g., ["vegetarian", "quick-meal", "spicy"])
        List<String> hashtags
) {}
