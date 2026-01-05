package com.pairingplanet.pairing_planet.dto.recipe;

import com.pairingplanet.pairing_planet.domain.enums.RecipeDifficulty;
import com.pairingplanet.pairing_planet.dto.food.FoodRequestDto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record CreateRecipeRequestDto(
        String title,
        String description,
        String culinaryLocale,
        UUID food1MasterPublicId, // [수정] Long ID 대신 UUID 사용
        String newFoodName,
        List<IngredientDto> ingredients,
        List<StepDto> steps,
        List<UUID> imagePublicIds,
        String changeCategory,
        UUID parentPublicId,
        UUID rootPublicId
) {}