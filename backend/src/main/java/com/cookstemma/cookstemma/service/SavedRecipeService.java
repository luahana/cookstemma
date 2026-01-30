package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.SavedRecipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.common.CursorPageResponse;
import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.recipe.SavedRecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.util.CursorUtil;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
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
    private final NotificationService notificationService;

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

            // Send notification to recipe owner (don't let notification failures affect save)
            try {
                User sender = userRepository.findById(userId).orElse(null);
                if (sender != null) {
                    notificationService.notifyRecipeSaved(recipe, sender);
                }
            } catch (Exception e) {
                // Log but don't fail the save operation
                System.err.println("Failed to send recipe saved notification: " + e.getMessage());
            }
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

    public boolean isSavedByUserPublicId(UUID recipePublicId, Long userId) {
        if (userId == null) return false;
        return recipeRepository.findByPublicId(recipePublicId)
                .map(recipe -> savedRecipeRepository.existsByUserIdAndRecipeId(userId, recipe.getId()))
                .orElse(false);
    }

    public Slice<RecipeSummaryDto> getSavedRecipes(Long userId, Pageable pageable, String locale) {
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        return savedRecipeRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(sr -> convertToSummary(sr.getRecipe(), normalizedLocale));
    }

    private RecipeSummaryDto convertToSummary(Recipe recipe, String locale) {
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
                .map(Hashtag::getName)
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

    /**
     * Get saved recipes with cursor-based pagination
     */
    public CursorPageResponse<RecipeSummaryDto> getSavedRecipesWithCursor(Long userId, String cursor, int size, String locale) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<SavedRecipe> savedRecipes;
        if (cursorData == null) {
            savedRecipes = savedRecipeRepository.findSavedRecipesWithCursorInitial(userId, pageable);
        } else {
            savedRecipes = savedRecipeRepository.findSavedRecipesWithCursor(userId, cursorData.createdAt(), cursorData.id(), pageable);
        }

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        List<RecipeSummaryDto> content = savedRecipes.getContent().stream()
                .map(sr -> convertToSummary(sr.getRecipe(), normalizedLocale))
                .toList();

        String nextCursor = null;
        if (savedRecipes.hasNext() && !savedRecipes.getContent().isEmpty()) {
            SavedRecipe lastItem = savedRecipes.getContent().get(savedRecipes.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getRecipeId());
        }

        return CursorPageResponse.of(content, nextCursor, size);
    }

    // ================================================================
    // Unified Dual Pagination Methods (Strategy Pattern)
    // ================================================================

    /**
     * Unified saved recipes with strategy-based pagination.
     * - If cursor is provided → cursor-based pagination (mobile)
     * - If page is provided → offset-based pagination (web)
     * - Default → cursor-based initial page
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<RecipeSummaryDto> getSavedRecipesUnified(Long userId, String cursor, Integer page, int size, String locale) {
        if (cursor != null && !cursor.isEmpty()) {
            return getSavedRecipesWithCursorUnified(userId, cursor, size, locale);
        } else if (page != null) {
            return getSavedRecipesWithOffset(userId, page, size, locale);
        } else {
            return getSavedRecipesWithCursorUnified(userId, null, size, locale);
        }
    }

    /**
     * Offset-based saved recipes for web clients.
     */
    private UnifiedPageResponse<RecipeSummaryDto> getSavedRecipesWithOffset(Long userId, int page, int size, String locale) {
        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);

        Page<SavedRecipe> savedRecipes = savedRecipeRepository.findSavedRecipesPage(userId, pageable);
        Page<RecipeSummaryDto> mappedPage = savedRecipes.map(sr -> convertToSummary(sr.getRecipe(), normalizedLocale));

        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based saved recipes wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<RecipeSummaryDto> getSavedRecipesWithCursorUnified(Long userId, String cursor, int size, String locale) {
        CursorPageResponse<RecipeSummaryDto> cursorResponse = getSavedRecipesWithCursor(userId, cursor, size, locale);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }
}
