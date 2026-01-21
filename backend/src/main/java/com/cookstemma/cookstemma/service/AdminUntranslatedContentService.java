package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import com.cookstemma.cookstemma.dto.admin.UntranslatedLogDto;
import com.cookstemma.cookstemma.dto.admin.UntranslatedRecipeDto;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.translation.TranslationEventRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminUntranslatedContentService {

    private static final int TOTAL_LOCALE_COUNT = 19;

    private final RecipeRepository recipeRepository;
    private final LogPostRepository logPostRepository;
    private final TranslationEventRepository translationEventRepository;
    private final TranslationEventService translationEventService;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public Page<UntranslatedRecipeDto> getUntranslatedRecipes(
            String title,
            String sortBy,
            String sortOrder,
            int page,
            int size) {

        Sort.Direction direction = "asc".equalsIgnoreCase(sortOrder)
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;
        Sort sort = Sort.by(direction, sortBy != null ? sortBy : "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<Recipe> recipes = (title != null && !title.isBlank())
                ? recipeRepository.findUntranslatedRecipesByTitle(title, pageable)
                : recipeRepository.findUntranslatedRecipes(pageable);

        List<Long> recipeIds = recipes.getContent().stream()
                .map(Recipe::getId)
                .toList();

        Map<Long, TranslationEvent> eventMap = getLatestTranslationEvents(
                TranslatableEntity.RECIPE_FULL, recipeIds);

        List<Long> creatorIds = recipes.getContent().stream()
                .map(Recipe::getCreatorId)
                .distinct()
                .toList();
        Map<Long, String> usernameMap = getUsernameMap(creatorIds);

        return recipes.map(recipe -> mapToRecipeDto(recipe, eventMap, usernameMap));
    }

    @Transactional(readOnly = true)
    public Page<UntranslatedLogDto> getUntranslatedLogs(
            String content,
            String sortBy,
            String sortOrder,
            int page,
            int size) {

        Sort.Direction direction = "asc".equalsIgnoreCase(sortOrder)
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;
        Sort sort = Sort.by(direction, sortBy != null ? sortBy : "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<LogPost> logs = (content != null && !content.isBlank())
                ? logPostRepository.findUntranslatedLogPostsByContent(content, pageable)
                : logPostRepository.findUntranslatedLogPosts(pageable);

        List<Long> logIds = logs.getContent().stream()
                .map(LogPost::getId)
                .toList();

        Map<Long, TranslationEvent> eventMap = getLatestTranslationEvents(
                TranslatableEntity.LOG_POST, logIds);

        List<Long> creatorIds = logs.getContent().stream()
                .map(LogPost::getCreatorId)
                .distinct()
                .toList();
        Map<Long, String> usernameMap = getUsernameMap(creatorIds);

        return logs.map(logPost -> mapToLogDto(logPost, eventMap, usernameMap));
    }

    @Transactional
    public int triggerRecipeRetranslation(List<UUID> recipePublicIds) {
        int count = 0;
        for (UUID publicId : recipePublicIds) {
            Recipe recipe = recipeRepository.findByPublicId(publicId).orElse(null);
            if (recipe != null) {
                translationEventService.forceRecipeTranslation(recipe, recipe.getCookingStyle());
                count++;
                log.info("Queued re-translation for recipe {}", publicId);
            }
        }
        return count;
    }

    @Transactional
    public int triggerLogRetranslation(List<UUID> logPublicIds) {
        int count = 0;
        for (UUID publicId : logPublicIds) {
            LogPost logPost = logPostRepository.findByPublicId(publicId).orElse(null);
            if (logPost != null) {
                translationEventService.queueLogPostTranslation(logPost);
                count++;
                log.info("Queued re-translation for log post {}", publicId);
            }
        }
        return count;
    }

    private Map<Long, TranslationEvent> getLatestTranslationEvents(
            TranslatableEntity entityType,
            List<Long> entityIds) {
        if (entityIds.isEmpty()) {
            return Map.of();
        }
        return translationEventRepository
                .findLatestByEntityTypeAndEntityIds(entityType, entityIds)
                .stream()
                .collect(Collectors.toMap(
                        TranslationEvent::getEntityId,
                        Function.identity(),
                        (e1, e2) -> e1.getCreatedAt().isAfter(e2.getCreatedAt()) ? e1 : e2
                ));
    }

    private Map<Long, String> getUsernameMap(List<Long> userIds) {
        if (userIds.isEmpty()) {
            return Map.of();
        }
        return userRepository.findAllById(userIds)
                .stream()
                .collect(Collectors.toMap(User::getId, User::getUsername));
    }

    private UntranslatedRecipeDto mapToRecipeDto(
            Recipe recipe,
            Map<Long, TranslationEvent> eventMap,
            Map<Long, String> usernameMap) {

        TranslationEvent event = eventMap.get(recipe.getId());
        TranslationStatus status = event != null ? event.getStatus() : null;
        String lastError = event != null ? event.getLastError() : null;

        int translatedCount = recipe.getTitleTranslations() != null
                ? recipe.getTitleTranslations().size()
                : 0;

        return UntranslatedRecipeDto.builder()
                .publicId(recipe.getPublicId())
                .title(recipe.getTitle())
                .cookingStyle(recipe.getCookingStyle())
                .translationStatus(status)
                .lastError(lastError)
                .translatedLocaleCount(translatedCount)
                .totalLocaleCount(TOTAL_LOCALE_COUNT)
                .creatorUsername(usernameMap.getOrDefault(recipe.getCreatorId(), "Unknown"))
                .createdAt(recipe.getCreatedAt())
                .build();
    }

    private UntranslatedLogDto mapToLogDto(
            LogPost logPost,
            Map<Long, TranslationEvent> eventMap,
            Map<Long, String> usernameMap) {

        TranslationEvent event = eventMap.get(logPost.getId());
        TranslationStatus status = event != null ? event.getStatus() : null;
        String lastError = event != null ? event.getLastError() : null;

        int translatedCount = logPost.getTitleTranslations() != null
                ? logPost.getTitleTranslations().size()
                : 0;

        String contentPreview = logPost.getContent() != null
                ? (logPost.getContent().length() > 100
                        ? logPost.getContent().substring(0, 100) + "..."
                        : logPost.getContent())
                : (logPost.getTitle() != null ? logPost.getTitle() : "");

        return UntranslatedLogDto.builder()
                .publicId(logPost.getPublicId())
                .content(contentPreview)
                .translationStatus(status)
                .lastError(lastError)
                .translatedLocaleCount(translatedCount)
                .totalLocaleCount(TOTAL_LOCALE_COUNT)
                .creatorUsername(usernameMap.getOrDefault(logPost.getCreatorId(), "Unknown"))
                .createdAt(logPost.getCreatedAt())
                .build();
    }
}
