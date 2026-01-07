package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.SavedRecipe;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeLogRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.repository.recipe.SavedRecipeRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SavedRecipeService {

    private final SavedRecipeRepository savedRecipeRepository;
    private final RecipeRepository recipeRepository;
    private final RecipeLogRepository recipeLogRepository;
    private final UserRepository userRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    @Transactional
    public void saveRecipe(UUID recipePublicId, Long userId) {
        Recipe recipe = recipeRepository.findByPublicId(recipePublicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        if (!savedRecipeRepository.existsByUserIdAndRecipeId(userId, recipe.getId())) {
            savedRecipeRepository.save(SavedRecipe.builder()
                    .userId(userId)
                    .recipeId(recipe.getId())
                    .build());
            recipe.incrementSavedCount();
        }
    }

    @Transactional
    public void unsaveRecipe(UUID recipePublicId, Long userId) {
        Recipe recipe = recipeRepository.findByPublicId(recipePublicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        if (savedRecipeRepository.existsByUserIdAndRecipeId(userId, recipe.getId())) {
            savedRecipeRepository.deleteByUserIdAndRecipeId(userId, recipe.getId());
            recipe.decrementSavedCount();
        }
    }

    public boolean isSavedByUser(Long recipeId, Long userId) {
        if (userId == null) return false;
        return savedRecipeRepository.existsByUserIdAndRecipeId(userId, recipeId);
    }

    public Slice<RecipeSummaryDto> getSavedRecipes(Long userId, Pageable pageable) {
        return savedRecipeRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(sr -> convertToSummary(sr.getRecipe()));
    }

    private RecipeSummaryDto convertToSummary(Recipe recipe) {
        String creatorName = userRepository.findById(recipe.getCreatorId())
                .map(User::getUsername)
                .orElse("Unknown");

        String foodName = getFoodName(recipe);

        String thumbnail = recipe.getImages().stream()
                .filter(img -> img.getType() == com.pairingplanet.pairing_planet.domain.enums.ImageType.THUMBNAIL)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        int variantCount = (int) recipeRepository.countByRootRecipeIdAndIsDeletedFalse(recipe.getId());
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());
        String rootTitle = recipe.getRootRecipe() != null ? recipe.getRootRecipe().getTitle() : null;

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                recipe.getTitle(),
                recipe.getDescription(),
                recipe.getCulinaryLocale(),
                creatorName,
                thumbnail,
                variantCount,
                logCount,
                recipe.getParentRecipe() != null ? recipe.getParentRecipe().getPublicId() : null,
                recipe.getRootRecipe() != null ? recipe.getRootRecipe().getPublicId() : null,
                rootTitle
        );
    }

    private String getFoodName(Recipe recipe) {
        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String locale = recipe.getCulinaryLocale();

        if (locale != null && nameMap.containsKey(locale)) {
            return nameMap.get(locale);
        }

        if (nameMap.containsKey("ko-KR")) {
            return nameMap.get("ko-KR");
        }

        return nameMap.values().stream().findFirst().orElse("Unknown Food");
    }
}
