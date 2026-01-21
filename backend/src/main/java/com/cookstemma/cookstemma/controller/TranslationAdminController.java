package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.service.TranslationEventService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * Admin controller for managing translations.
 * All endpoints require ADMIN role.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/admin/translations")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class TranslationAdminController {

    private final TranslationEventService translationEventService;
    private final RecipeRepository recipeRepository;

    /**
     * Force re-translation of a recipe with a specified source locale.
     * Use this when the recipe's cookingStyle doesn't match the actual content language.
     *
     * POST /api/v1/admin/translations/recipes/{publicId}/retranslate
     *
     * @param publicId Recipe's public ID
     * @param request Contains sourceLocale (e.g., "en" if content is actually English)
     * @return Success message
     */
    @PostMapping("/recipes/{publicId}/retranslate")
    public ResponseEntity<Map<String, Object>> retranslateRecipe(
            @PathVariable UUID publicId,
            @RequestBody RetranslateRequest request
    ) {
        Recipe recipe = recipeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found: " + publicId));

        translationEventService.forceRecipeTranslation(recipe, request.sourceLocale());

        log.info("Admin triggered re-translation for recipe {} with source locale {}",
                publicId, request.sourceLocale());

        return ResponseEntity.ok(Map.of(
                "message", "Translation queued successfully",
                "recipePublicId", publicId,
                "sourceLocale", request.sourceLocale(),
                "targetLocales", 20 // All locales
        ));
    }

    /**
     * Backfill translations for all FoodMaster entries that only have one locale.
     * This queues translation events for foods that were created before the
     * automatic translation system was in place.
     *
     * POST /api/v1/admin/translations/foods/backfill
     *
     * @return Number of foods queued for translation
     */
    @PostMapping("/foods/backfill")
    public ResponseEntity<Map<String, Object>> backfillFoodTranslations() {
        int count = translationEventService.queueUntranslatedFoodMasters();

        log.info("Admin triggered backfill for {} untranslated foods", count);

        return ResponseEntity.ok(Map.of(
                "message", "Backfill queued successfully",
                "foodsQueued", count
        ));
    }

    public record RetranslateRequest(String sourceLocale) {}
}
