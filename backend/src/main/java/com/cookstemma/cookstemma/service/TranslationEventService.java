package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.autocomplete.AutocompleteItem;
import com.cookstemma.cookstemma.domain.entity.comment.Comment;
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
import com.cookstemma.cookstemma.util.LocaleUtils;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import software.amazon.awssdk.services.sqs.model.SqsException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class TranslationEventService {

    private final TranslationEventRepository translationEventRepository;
    private final FoodMasterRepository foodMasterRepository;
    private final ObjectMapper objectMapper;

    @Autowired(required = false)
    private SqsClient sqsClient;

    @Value("${aws.sqs.translation-queue-url:}")
    private String translationQueueUrl;

    @Value("${aws.sqs.enabled:false}")
    private boolean sqsEnabled;

    // All supported languages in BCP47 format (20 total)
    private static final List<String> ALL_LOCALES = List.of(
            "en-US", "zh-CN", "es-ES", "ja-JP", "de-DE", "fr-FR", "pt-BR", "ko-KR", "it-IT", "ar-SA",
            "ru-RU", "id-ID", "vi-VN", "hi-IN", "th-TH", "pl-PL", "tr-TR", "nl-NL", "sv-SE", "fa-IR"
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
     * Send translation event to SQS for immediate processing.
     * Hybrid architecture: SQS provides real-time processing, EventBridge is safety net.
     *
     * @param event The translation event that was saved to database
     */
    private void sendToSqs(TranslationEvent event) {
        // Skip if SQS is disabled or not configured
        if (!sqsEnabled || sqsClient == null || translationQueueUrl == null || translationQueueUrl.isEmpty()) {
            log.debug("SQS disabled or not configured, event {} will be picked up by EventBridge", event.getId());
            return;
        }

        try {
            // Create SQS message body
            Map<String, Object> messageBody = new HashMap<>();
            messageBody.put("event_id", event.getId());
            messageBody.put("entity_type", event.getEntityType().name());
            messageBody.put("entity_id", event.getEntityId());

            String messageJson = objectMapper.writeValueAsString(messageBody);

            // Send to SQS
            SendMessageRequest request = SendMessageRequest.builder()
                    .queueUrl(translationQueueUrl)
                    .messageBody(messageJson)
                    .build();

            sqsClient.sendMessage(request);

            log.info("Sent {} translation event {} to SQS for immediate processing",
                    event.getEntityType(), event.getId());

        } catch (JsonProcessingException e) {
            // Log but don't fail - EventBridge will pick it up
            log.warn("Failed to serialize SQS message for event {}, will be picked up by EventBridge: {}",
                    event.getId(), e.getMessage());
        } catch (SqsException e) {
            // Log but don't fail - EventBridge will pick it up
            log.warn("Failed to send event {} to SQS ({}), will be picked up by EventBridge in ~5 minutes",
                    event.getId(), e.getMessage());
        } catch (Exception e) {
            // Catch all other exceptions to prevent translation from failing
            log.error("Unexpected error sending event {} to SQS, will be picked up by EventBridge: {}",
                    event.getId(), e.getMessage(), e);
        }
    }

    /**
     * Queue a full recipe translation (title, description, all steps, all ingredients).
     * Uses RECIPE_FULL entity type for context-aware translation in a single API call.
     *
     * Hybrid Architecture:
     * 1. Saves event to database (source of truth)
     * 2. Sends to SQS for immediate processing (~1 min latency)
     * 3. If SQS fails, EventBridge picks it up (~5 min latency)
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

        // Push to SQS for immediate processing (hybrid architecture)
        sendToSqs(event);
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

        // Push to SQS for immediate processing
        sendToSqs(event);
    }

    /**
     * Queue comment translation.
     * Uses the creator's locale setting as source locale.
     * Content moderation is performed by the Lambda handler before translation.
     * If moderation fails, the comment will be hidden instead of translated.
     */
    @Transactional
    public void queueCommentTranslation(Comment comment) {
        if (comment.getContent() == null || comment.getContent().isBlank()) {
            log.debug("Comment {} has no content to translate", comment.getId());
            return;
        }

        String sourceLocale = normalizeLocale(comment.getCreator().getLocale());
        List<String> targetLocales = getTargetLocales(sourceLocale);

        if (targetLocales.isEmpty()) {
            log.debug("No target locales for comment {} (source: {})", comment.getId(), sourceLocale);
            return;
        }

        if (isTranslationPending(TranslatableEntity.COMMENT, comment.getId())) {
            log.debug("Translation already pending for comment {}", comment.getId());
            return;
        }

        TranslationEvent event = TranslationEvent.builder()
                .entityType(TranslatableEntity.COMMENT)
                .entityId(comment.getId())
                .sourceLocale(sourceLocale)
                .targetLocales(targetLocales)
                .build();

        translationEventRepository.save(event);
        log.info("Queued translation for comment {} (source: {}, targets: {})",
                comment.getId(), sourceLocale, targetLocales.size());

        // Push to SQS for immediate processing
        sendToSqs(event);
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

        // Translate to all locales except source (can't translate a language to itself)
        List<String> targetLocales = new ArrayList<>(ALL_LOCALES);
        targetLocales.remove(normalized);

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

    private static final String DEFAULT_LOCALE = "en-US";

    /**
     * Normalize locale to BCP47 format for consistent translation keys.
     * Handles country codes (KR → ko-KR), short codes (ko → ko-KR), and full BCP47 (ko-KR → ko-KR).
     * Unknown locales default to en-US.
     */
    private String normalizeLocale(String locale) {
        if (locale == null || locale.isBlank()) {
            return DEFAULT_LOCALE;
        }

        // Handle country-only codes first (e.g., "KR" from cookingStyle)
        String firstPart = locale.split("[-_]")[0];
        String upper = firstPart.toUpperCase();

        if (COUNTRY_TO_LANGUAGE.containsKey(upper)) {
            // Convert country code to language code, then to BCP47
            String langCode = COUNTRY_TO_LANGUAGE.get(upper);
            return LocaleUtils.toBcp47(langCode);
        }

        // Convert to BCP47 and check if it's a supported locale
        String bcp47 = LocaleUtils.toBcp47(locale);

        // If the resulting BCP47 locale is not in our supported list, default to en-US
        if (!ALL_LOCALES.contains(bcp47)) {
            return DEFAULT_LOCALE;
        }

        return bcp47;
    }

    private List<String> getTargetLocales(String sourceLocale) {
        List<String> targets = new ArrayList<>(ALL_LOCALES);
        targets.remove(sourceLocale);
        return targets;
    }
}
