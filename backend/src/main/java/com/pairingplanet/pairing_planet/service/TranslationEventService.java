package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.autocomplete.AutocompleteItem;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeIngredient;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeStep;
import com.pairingplanet.pairing_planet.domain.entity.translation.TranslationEvent;
import com.pairingplanet.pairing_planet.domain.enums.TranslatableEntity;
import com.pairingplanet.pairing_planet.domain.enums.TranslationStatus;
import com.pairingplanet.pairing_planet.repository.translation.TranslationEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class TranslationEventService {

    private final TranslationEventRepository translationEventRepository;

    // All supported languages (20 total)
    private static final List<String> ALL_LOCALES = List.of(
            "en", "zh", "es", "ja", "de", "fr", "pt", "ko", "it", "ar",
            "ru", "id", "vi", "hi", "th", "pl", "tr", "nl", "sv", "fa"
    );

    @Transactional
    public void queueRecipeTranslation(Recipe recipe) {
        String sourceLocale = normalizeLocale(recipe.getCookingStyle());
        List<String> targetLocales = getTargetLocales(sourceLocale);

        if (targetLocales.isEmpty()) {
            log.debug("No target locales for recipe {} (source: {})", recipe.getId(), sourceLocale);
            return;
        }

        // Check if translation already pending
        if (isTranslationPending(TranslatableEntity.RECIPE, recipe.getId())) {
            log.debug("Translation already pending for recipe {}", recipe.getId());
            return;
        }

        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.RECIPE)
                .entityId(recipe.getId())
                .sourceLocale(sourceLocale)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
        log.info("Queued translation for recipe {} (source: {}, targets: {})",
                recipe.getId(), sourceLocale, targetLocales.size());

        // Also queue translations for steps and ingredients
        for (RecipeStep step : recipe.getSteps()) {
            queueRecipeStepTranslation(step, sourceLocale);
        }
        for (RecipeIngredient ingredient : recipe.getIngredients()) {
            queueRecipeIngredientTranslation(ingredient, sourceLocale);
        }
    }

    @Transactional
    public void queueRecipeStepTranslation(RecipeStep step, String sourceLocale) {
        String normalized = normalizeLocale(sourceLocale);
        List<String> targetLocales = getTargetLocales(normalized);

        if (targetLocales.isEmpty()) {
            return;
        }

        if (isTranslationPending(TranslatableEntity.RECIPE_STEP, step.getId())) {
            return;
        }

        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.RECIPE_STEP)
                .entityId(step.getId())
                .sourceLocale(normalized)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
    }

    @Transactional
    public void queueRecipeIngredientTranslation(RecipeIngredient ingredient, String sourceLocale) {
        String normalized = normalizeLocale(sourceLocale);
        List<String> targetLocales = getTargetLocales(normalized);

        if (targetLocales.isEmpty()) {
            return;
        }

        if (isTranslationPending(TranslatableEntity.RECIPE_INGREDIENT, ingredient.getId())) {
            return;
        }

        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.RECIPE_INGREDIENT)
                .entityId(ingredient.getId())
                .sourceLocale(normalized)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
    }

    @Transactional
    public void queueLogPostTranslation(LogPost logPost) {
        String sourceLocale = normalizeLocale(logPost.getLocale());
        List<String> targetLocales = getTargetLocales(sourceLocale);

        if (targetLocales.isEmpty()) {
            log.debug("No target locales for log post {} (source: {})", logPost.getId(), sourceLocale);
            return;
        }

        if (isTranslationPending(TranslatableEntity.LOG_POST, logPost.getId())) {
            log.debug("Translation already pending for log post {}", logPost.getId());
            return;
        }

        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.LOG_POST)
                .entityId(logPost.getId())
                .sourceLocale(sourceLocale)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
        log.info("Queued translation for log post {} (source: {}, targets: {})",
                logPost.getId(), sourceLocale, targetLocales.size());
    }

    @Transactional
    public void queueFoodMasterTranslation(FoodMaster foodMaster, String sourceLocale) {
        String normalized = normalizeLocale(sourceLocale);
        List<String> targetLocales = getTargetLocales(normalized);

        if (targetLocales.isEmpty()) {
            log.debug("No target locales for food master {} (source: {})", foodMaster.getId(), normalized);
            return;
        }

        if (isTranslationPending(TranslatableEntity.FOOD_MASTER, foodMaster.getId())) {
            log.debug("Translation already pending for food master {}", foodMaster.getId());
            return;
        }

        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.FOOD_MASTER)
                .entityId(foodMaster.getId())
                .sourceLocale(normalized)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
        log.info("Queued translation for food master {} (source: {}, targets: {})",
                foodMaster.getId(), normalized, targetLocales.size());
    }

    @Transactional
    public void queueAutocompleteItemTranslation(AutocompleteItem autocompleteItem, String sourceLocale) {
        String normalized = normalizeLocale(sourceLocale);
        List<String> targetLocales = getTargetLocales(normalized);

        if (targetLocales.isEmpty()) {
            log.debug("No target locales for autocomplete item {} (source: {})",
                    autocompleteItem.getId(), normalized);
            return;
        }

        if (isTranslationPending(TranslatableEntity.AUTOCOMPLETE_ITEM, autocompleteItem.getId())) {
            log.debug("Translation already pending for autocomplete item {}", autocompleteItem.getId());
            return;
        }

        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.AUTOCOMPLETE_ITEM)
                .entityId(autocompleteItem.getId())
                .sourceLocale(normalized)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
        log.info("Queued translation for autocomplete item {} (source: {}, targets: {})",
                autocompleteItem.getId(), normalized, targetLocales.size());
    }

    @Transactional(readOnly = true)
    public List<TranslationEvent> getRetryableEvents() {
        return translationEventRepository.findRetryable();
    }

    @Transactional
    public void markEventProcessing(TranslationEvent event) {
        event.markProcessing();
        translationEventRepository.save(event);
    }

    @Transactional
    public void markEventCompleted(TranslationEvent event) {
        event.markCompleted();
        translationEventRepository.save(event);
    }

    @Transactional
    public void markEventFailed(TranslationEvent event, String error) {
        event.markFailed(error);
        translationEventRepository.save(event);
    }

    @Transactional
    public void addCompletedLocale(TranslationEvent event, String locale) {
        event.addCompletedLocale(locale);
        if (event.isAllLocalesCompleted()) {
            event.markCompleted();
        }
        translationEventRepository.save(event);
    }

    private boolean isTranslationPending(TranslatableEntity entityType, Long entityId) {
        return translationEventRepository.existsByEntityTypeAndEntityIdAndStatusIn(
                entityType, entityId, List.of(TranslationStatus.PENDING, TranslationStatus.PROCESSING));
    }

    private String normalizeLocale(String locale) {
        if (locale == null || locale.isBlank()) {
            return "ko";
        }
        // Convert "ko-KR" → "ko", "en-US" → "en", etc.
        String normalized = locale.split("[-_]")[0].toLowerCase();
        return ALL_LOCALES.contains(normalized) ? normalized : "ko";
    }

    private List<String> getTargetLocales(String sourceLocale) {
        List<String> targets = new ArrayList<>(ALL_LOCALES);
        targets.remove(sourceLocale);
        return targets;
    }
}
