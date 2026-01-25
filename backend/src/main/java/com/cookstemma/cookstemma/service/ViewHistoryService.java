package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.history.ViewHistory;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ViewableEntityType;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.repository.history.ViewHistoryRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
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
public class ViewHistoryService {

    private final ViewHistoryRepository viewHistoryRepository;
    private final RecipeRepository recipeRepository;
    private final LogPostRepository logPostRepository;
    private final RecipeLogRepository recipeLogRepository;
    private final UserRepository userRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    private static final int MAX_HISTORY_PER_USER = 50;

    /**
     * Record a view of a recipe.
     */
    @Transactional
    public void recordRecipeView(UUID recipePublicId, Long userId) {
        Recipe recipe = recipeRepository.findByPublicId(recipePublicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        recordView(userId, ViewableEntityType.RECIPE, recipe.getId());
    }

    /**
     * Record a view of a log post.
     */
    @Transactional
    public void recordLogView(UUID logPublicId, Long userId) {
        LogPost logPost = logPostRepository.findByPublicId(logPublicId)
                .orElseThrow(() -> new IllegalArgumentException("Log post not found"));

        recordView(userId, ViewableEntityType.LOG_POST, logPost.getId());
    }

    /**
     * Clear all view history for a user.
     */
    @Transactional
    public void clearViewHistory(Long userId) {
        viewHistoryRepository.deleteAllByUserId(userId);
    }

    /**
     * Record a view, updating timestamp if already exists.
     */
    private void recordView(Long userId, ViewableEntityType entityType, Long entityId) {
        viewHistoryRepository.findByUserIdAndEntityTypeAndEntityId(userId, entityType, entityId)
                .ifPresentOrElse(
                        vh -> {
                            vh.updateViewedAt();
                            viewHistoryRepository.save(vh);
                        },
                        () -> {
                            ViewHistory newView = ViewHistory.builder()
                                    .userId(userId)
                                    .entityType(entityType)
                                    .entityId(entityId)
                                    .build();
                            viewHistoryRepository.save(newView);

                            // Cleanup old entries if exceeding limit
                            cleanupOldEntries(userId);
                        }
                );
    }

    /**
     * Delete oldest entries if user has more than MAX_HISTORY_PER_USER.
     */
    private void cleanupOldEntries(Long userId) {
        long count = viewHistoryRepository.countByUserId(userId);
        if (count > MAX_HISTORY_PER_USER) {
            int toDelete = (int) (count - MAX_HISTORY_PER_USER);
            List<Long> oldestIds = viewHistoryRepository.findOldestIdsByUserId(userId, PageRequest.of(0, toDelete));
            if (!oldestIds.isEmpty()) {
                viewHistoryRepository.deleteAllById(oldestIds);
            }
        }
    }

    /**
     * Get recently viewed recipes for a user.
     * @param locale locale for translations
     */
    @Transactional(readOnly = true)
    public List<RecipeSummaryDto> getRecentlyViewedRecipes(Long userId, int limit, String locale) {
        List<Long> recipeIds = viewHistoryRepository.findRecentEntityIdsByUserAndType(
                userId,
                ViewableEntityType.RECIPE,
                PageRequest.of(0, limit)
        );

        if (recipeIds.isEmpty()) {
            return List.of();
        }

        // Fetch recipes and maintain view order
        Map<Long, Recipe> recipeMap = recipeRepository.findAllById(recipeIds)
                .stream()
                .filter(r -> r.getDeletedAt() == null && !Boolean.TRUE.equals(r.getIsPrivate()))
                .collect(Collectors.toMap(Recipe::getId, Function.identity()));

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        return recipeIds.stream()
                .filter(recipeMap::containsKey)
                .map(id -> convertRecipeToSummary(recipeMap.get(id), normalizedLocale))
                .toList();
    }

    /**
     * Get recently viewed log posts for a user.
     * @param locale locale for translations
     */
    @Transactional(readOnly = true)
    public List<LogPostSummaryDto> getRecentlyViewedLogs(Long userId, int limit, String locale) {
        List<Long> logIds = viewHistoryRepository.findRecentEntityIdsByUserAndType(
                userId,
                ViewableEntityType.LOG_POST,
                PageRequest.of(0, limit)
        );

        if (logIds.isEmpty()) {
            return List.of();
        }

        // Fetch logs and maintain view order
        Map<Long, LogPost> logMap = logPostRepository.findAllById(logIds)
                .stream()
                .filter(lp -> lp.getDeletedAt() == null)
                .collect(Collectors.toMap(LogPost::getId, Function.identity()));

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        return logIds.stream()
                .filter(logMap::containsKey)
                .map(id -> convertLogToSummary(logMap.get(id), normalizedLocale))
                .toList();
    }

    private RecipeSummaryDto convertRecipeToSummary(Recipe recipe, String locale) {
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // Locale-aware food name
        String foodName = LocaleUtils.getLocalizedValue(
                recipe.getFoodMaster().getName(),
                locale,
                recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));

        String thumbnail = recipe.getCoverImages().stream()
                .filter(img -> img.getType() == com.cookstemma.cookstemma.domain.enums.ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());

        // Locale-aware root title
        String rootTitle = null;
        if (recipe.getRootRecipe() != null) {
            rootTitle = LocaleUtils.getLocalizedValue(
                    recipe.getRootRecipe().getTitleTranslations(),
                    locale,
                    recipe.getRootRecipe().getTitle());
        }

        List<String> hashtags = recipe.getHashtags().stream()
                .map(h -> h.getName())
                .limit(3)
                .toList();

        // Locale-aware title and description
        String localizedTitle = LocaleUtils.getLocalizedValue(
                recipe.getTitleTranslations(), locale, recipe.getTitle());
        String localizedDescription = LocaleUtils.getLocalizedValue(
                recipe.getDescriptionTranslations(), locale, recipe.getDescription());

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                localizedTitle,
                localizedDescription,
                recipe.getCookingStyle(),
                creatorPublicId,
                userName,
                thumbnail,
                variantCount,
                logCount,
                recipe.getParentRecipe() != null ? recipe.getParentRecipe().getPublicId() : null,
                recipe.getRootRecipe() != null ? recipe.getRootRecipe().getPublicId() : null,
                rootTitle,
                recipe.getServings() != null ? recipe.getServings() : 2,
                recipe.getCookingTimeRange() != null ? recipe.getCookingTimeRange().name() : "MIN_30_TO_60",
                hashtags,
                recipe.getIsPrivate() != null ? recipe.getIsPrivate() : false
        );
    }

    private LogPostSummaryDto convertLogToSummary(LogPost logPost, String locale) {
        User creator = userRepository.findById(logPost.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = logPost.getImages().isEmpty()
                ? null
                : urlPrefix + "/" + logPost.getImages().get(0).getStoredFilename();

        // Get food name, recipe title, and variant status from linked recipe (locale-aware)
        var recipeLog = logPost.getRecipeLog();
        String foodName = null;
        String recipeTitle = null;
        Boolean isVariant = false;
        if (recipeLog != null && recipeLog.getRecipe() != null) {
            Recipe recipe = recipeLog.getRecipe();
            foodName = LocaleUtils.getLocalizedValue(
                    recipe.getFoodMaster().getName(),
                    locale,
                    recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));
            recipeTitle = LocaleUtils.getLocalizedValue(
                    recipe.getTitleTranslations(), locale, recipe.getTitle());
            isVariant = recipe.getRootRecipe() != null;
        }

        List<String> hashtags = logPost.getHashtags().stream()
                .map(h -> h.getName())
                .limit(3)
                .toList();

        // Locale-aware title and content
        String localizedTitle = LocaleUtils.getLocalizedValue(
                logPost.getTitleTranslations(), locale, logPost.getTitle());
        String localizedContent = LocaleUtils.getLocalizedValue(
                logPost.getContentTranslations(), locale, logPost.getContent());

        return new LogPostSummaryDto(
                logPost.getPublicId(),
                localizedTitle,
                localizedContent,
                recipeLog != null ? recipeLog.getRating() : null,
                thumbnailUrl,
                creatorPublicId,
                userName,
                foodName,
                recipeTitle,
                hashtags,
                isVariant,
                logPost.getIsPrivate() != null ? logPost.getIsPrivate() : false,
                logPost.getCommentCount() != null ? logPost.getCommentCount() : 0,
                logPost.getLocale()
        );
    }
}
