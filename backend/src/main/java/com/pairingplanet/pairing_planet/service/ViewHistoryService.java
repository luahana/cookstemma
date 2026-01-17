package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.history.ViewHistory;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.ViewableEntityType;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;
import com.pairingplanet.pairing_planet.repository.history.ViewHistoryRepository;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeLogRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
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
                        }
                );
    }

    /**
     * Get recently viewed recipes for a user.
     */
    @Transactional(readOnly = true)
    public List<RecipeSummaryDto> getRecentlyViewedRecipes(Long userId, int limit) {
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

        return recipeIds.stream()
                .filter(recipeMap::containsKey)
                .map(id -> convertRecipeToSummary(recipeMap.get(id)))
                .toList();
    }

    /**
     * Get recently viewed log posts for a user.
     */
    @Transactional(readOnly = true)
    public List<LogPostSummaryDto> getRecentlyViewedLogs(Long userId, int limit) {
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

        return logIds.stream()
                .filter(logMap::containsKey)
                .map(id -> convertLogToSummary(logMap.get(id)))
                .toList();
    }

    private RecipeSummaryDto convertRecipeToSummary(Recipe recipe) {
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String foodName = recipe.getFoodMaster().getNameByLocale(recipe.getCulinaryLocale());

        String thumbnail = recipe.getImages().stream()
                .filter(img -> img.getType() == com.pairingplanet.pairing_planet.domain.enums.ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());

        String rootTitle = recipe.getRootRecipe() != null ? recipe.getRootRecipe().getTitle() : null;

        List<String> hashtags = recipe.getHashtags().stream()
                .map(h -> h.getName())
                .limit(3)
                .toList();

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                recipe.getTitle(),
                recipe.getDescription(),
                recipe.getCulinaryLocale(),
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
                hashtags
        );
    }

    private LogPostSummaryDto convertLogToSummary(LogPost logPost) {
        User creator = userRepository.findById(logPost.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = logPost.getImages().isEmpty()
                ? null
                : urlPrefix + "/" + logPost.getImages().get(0).getStoredFilename();

        // Get food name and variant status from linked recipe
        var recipeLog = logPost.getRecipeLog();
        String foodName = null;
        Boolean isVariant = false;
        if (recipeLog != null && recipeLog.getRecipe() != null) {
            Recipe recipe = recipeLog.getRecipe();
            foodName = recipe.getFoodMaster().getNameByLocale(recipe.getCulinaryLocale());
            isVariant = recipe.getRootRecipe() != null;
        }

        List<String> hashtags = logPost.getHashtags().stream()
                .map(h -> h.getName())
                .limit(3)
                .toList();

        return new LogPostSummaryDto(
                logPost.getPublicId(),
                logPost.getTitle(),
                recipeLog != null ? recipeLog.getOutcome() : null,
                thumbnailUrl,
                creatorPublicId,
                userName,
                foodName,
                hashtags,
                isVariant
        );
    }
}
