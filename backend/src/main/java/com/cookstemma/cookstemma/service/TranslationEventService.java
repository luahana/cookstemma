package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.autocomplete.AutocompleteItem;
import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeIngredient;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeStep;
import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.translation.TranslationEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class TranslationEventService {

    private final TranslationEventRepository translationEventRepository;
    private final FoodMasterRepository foodMasterRepository;

    // All supported languages (20 total)
    private static final List<String> ALL_LOCALES = List.of(
            "en", "zh", "es", "ja", "de", "fr", "pt", "ko", "it", "ar",
            "ru", "id", "vi", "hi", "th", "pl", "tr", "nl", "sv", "fa"
    );

    // Country code to language code mapping (cookingStyle uses country codes)
    private static final Map<String, String> COUNTRY_TO_LANGUAGE = Map.ofEntries(
            Map.entry("KR", "ko"),  // Korea → Korean
            Map.entry("US", "en"),  // USA → English
            Map.entry("GB", "en"),  // UK → English
            Map.entry("JP", "ja"),  // Japan → Japanese
            Map.entry("CN", "zh"),  // China → Chinese
            Map.entry("TW", "zh"),  // Taiwan → Chinese
            Map.entry("FR", "fr"),  // France → French
            Map.entry("DE", "de"),  // Germany → German
            Map.entry("ES", "es"),  // Spain → Spanish
            Map.entry("MX", "es"),  // Mexico → Spanish
            Map.entry("IT", "it"),  // Italy → Italian
            Map.entry("PT", "pt"),  // Portugal → Portuguese
            Map.entry("BR", "pt"),  // Brazil → Portuguese
            Map.entry("RU", "ru"),  // Russia → Russian
            Map.entry("SA", "ar"),  // Saudi Arabia → Arabic
            Map.entry("AE", "ar"),  // UAE → Arabic
            Map.entry("EG", "ar"),  // Egypt → Arabic
            Map.entry("ID", "id"),  // Indonesia → Indonesian
            Map.entry("VN", "vi"),  // Vietnam → Vietnamese
            Map.entry("IN", "hi"),  // India → Hindi
            Map.entry("TH", "th"),  // Thailand → Thai
            Map.entry("PL", "pl"),  // Poland → Polish
            Map.entry("TR", "tr"),  // Turkey → Turkish
            Map.entry("NL", "nl"),  // Netherlands → Dutch
            Map.entry("SE", "sv"),  // Sweden → Swedish
            Map.entry("IR", "fa")   // Iran → Persian
    );

    /**
     * Queue a full recipe translation (title, description, all steps, all ingredients).
     * Uses RECIPE_FULL entity type for context-aware translation in a single API call.
     */
    @Transactional
    public void queueRecipeTranslation(Recipe recipe) {
        String sourceLocale = normalizeLocale(recipe.getCookingStyle());
        List<String> targetLocales = getTargetLocales(sourceLocale);

        if (targetLocales.isEmpty()) {
            log.debug("No target locales for recipe {} (source: {})", recipe.getId(), sourceLocale);
            return;
        }

        // Check if translation already pending (using RECIPE_FULL)
        if (isTranslationPending(TranslatableEntity.RECIPE_FULL, recipe.getId())) {
            log.debug("Translation already pending for recipe {}", recipe.getId());
            return;
        }

        // Create single RECIPE_FULL event (replaces RECIPE + RECIPE_STEP + RECIPE_INGREDIENT events)
        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.RECIPE_FULL)
                .entityId(recipe.getId())
                .sourceLocale(sourceLocale)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
        log.info("Queued full recipe translation for recipe {} ({} steps, {} ingredients, source: {}, targets: {})",
                recipe.getId(), recipe.getSteps().size(), recipe.getIngredients().size(),
                sourceLocale, targetLocales.size());
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

    /**
     * Queue user bio translation.
     * Uses the user's locale setting as source locale.
     */
    @Transactional
    public void queueUserBioTranslation(User user) {
        if (user.getBio() == null || user.getBio().isBlank()) {
            log.debug("User {} has no bio to translate", user.getId());
            return;
        }

        String sourceLocale = normalizeLocale(user.getLocale());
        List<String> targetLocales = getTargetLocales(sourceLocale);

        if (targetLocales.isEmpty()) {
            log.debug("No target locales for user {} (source: {})", user.getId(), sourceLocale);
            return;
        }

        if (isTranslationPending(TranslatableEntity.USER, user.getId())) {
            log.debug("Translation already pending for user {}", user.getId());
            return;
        }

        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.USER)
                .entityId(user.getId())
                .sourceLocale(sourceLocale)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
        log.info("Queued bio translation for user {} (source: {}, targets: {})",
                user.getId(), sourceLocale, targetLocales.size());
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

    /**
     * Queue translations for all FoodMaster entries that only have one locale.
     * Used for backfilling translations for existing untranslated foods.
     *
     * @return The number of foods queued for translation
     */
    @Transactional
    public int queueUntranslatedFoodMasters() {
        List<FoodMaster> untranslated = foodMasterRepository.findUntranslatedFoods();
        int count = 0;

        for (FoodMaster food : untranslated) {
            if (food.getName() == null || food.getName().isEmpty()) {
                continue;
            }
            String sourceLocale = food.getName().keySet().iterator().next();
            queueFoodMasterTranslation(food, sourceLocale);
            count++;
        }

        log.info("Queued {} untranslated FoodMaster entries for translation", count);
        return count;
    }

    /**
     * Force re-translation of a recipe with a specified source locale.
     * This is useful when the recipe's cookingStyle doesn't match the actual content language.
     * Uses RECIPE_FULL for context-aware translation of entire recipe in a single API call.
     *
     * @param recipe The recipe to re-translate
     * @param sourceLocale The actual language of the content (e.g., "en" if content is English)
     */
    @Transactional
    public void forceRecipeTranslation(Recipe recipe, String sourceLocale) {
        String normalized = normalizeLocale(sourceLocale);

        // Translate to ALL locales (not excluding source, since we want full coverage)
        List<String> targetLocales = new ArrayList<>(ALL_LOCALES);

        // Cancel any existing pending translations for this recipe (all types)
        cancelPendingTranslations(TranslatableEntity.RECIPE_FULL, recipe.getId());
        cancelPendingTranslations(TranslatableEntity.RECIPE, recipe.getId());
        for (RecipeStep step : recipe.getSteps()) {
            cancelPendingTranslations(TranslatableEntity.RECIPE_STEP, step.getId());
        }
        for (RecipeIngredient ingredient : recipe.getIngredients()) {
            cancelPendingTranslations(TranslatableEntity.RECIPE_INGREDIENT, ingredient.getId());
        }

        // Queue single RECIPE_FULL translation (includes steps and ingredients)
        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.RECIPE_FULL)
                .entityId(recipe.getId())
                .sourceLocale(normalized)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
        log.info("Force-queued full recipe translation for recipe {} ({} steps, {} ingredients, source: {}, targets: all {})",
                recipe.getId(), recipe.getSteps().size(), recipe.getIngredients().size(),
                normalized, targetLocales.size());
    }

    private void cancelPendingTranslations(TranslatableEntity entityType, Long entityId) {
        List<TranslationEvent> pendingEvents = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                entityType, entityId, List.of(TranslationStatus.PENDING, TranslationStatus.PROCESSING));

        for (TranslationEvent event : pendingEvents) {
            event.markFailed("Cancelled for re-translation");
            translationEventRepository.save(event);
        }
    }

    private boolean isTranslationPending(TranslatableEntity entityType, Long entityId) {
        return translationEventRepository.existsByEntityTypeAndEntityIdAndStatusIn(
                entityType, entityId, List.of(TranslationStatus.PENDING, TranslationStatus.PROCESSING));
    }

    private String normalizeLocale(String locale) {
        if (locale == null || locale.isBlank()) {
            return "ko";
        }

        String normalized = locale.split("[-_]")[0];
        String upper = normalized.toUpperCase();
        String lower = normalized.toLowerCase();

        // First check if it's a country code (e.g., "SA", "KR", "TR")
        if (COUNTRY_TO_LANGUAGE.containsKey(upper)) {
            return COUNTRY_TO_LANGUAGE.get(upper);
        }

        // Then check if it's already a language code (e.g., "ko", "en", "ar")
        if (ALL_LOCALES.contains(lower)) {
            return lower;
        }

        // Default to Korean
        return "ko";
    }

    private List<String> getTargetLocales(String sourceLocale) {
        List<String> targets = new ArrayList<>(ALL_LOCALES);
        targets.remove(sourceLocale);
        return targets;
    }
}
