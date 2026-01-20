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

    public boolean isSavedByUserPublicId(UUID recipePublicId, Long userId) {
        if (userId == null) return false;
        return recipeRepository.findByPublicId(recipePublicId)
                .map(recipe -> savedRecipeRepository.existsByUserIdAndRecipeId(userId, recipe.getId()))
                .orElse(false);
    }

    public Slice<RecipeSummaryDto> getSavedRecipes(Long userId, Pageable pageable) {
        return savedRecipeRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(sr -> convertToSummary(sr.getRecipe()));
    }

    private RecipeSummaryDto convertToSummary(Recipe recipe) {
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String foodName = getFoodName(recipe);

        String thumbnail = recipe.getCoverImages().stream()
                .filter(img -> img.getType() == com.cookstemma.cookstemma.domain.enums.ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());
        String rootTitle = recipe.getRootRecipe() != null ? recipe.getRootRecipe().getTitle() : null;
        List<String> hashtags = recipe.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                recipe.getTitle(),
                recipe.getDescription(),
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
                recipe.getTitleTranslations(),
                recipe.getDescriptionTranslations()
        );
    }

    private String getFoodName(Recipe recipe) {
        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String locale = recipe.getCookingStyle();

        if (locale != null && nameMap.containsKey(locale)) {
            return nameMap.get(locale);
        }

        if (nameMap.containsKey("ko-KR")) {
            return nameMap.get("ko-KR");
        }

        return nameMap.values().stream().findFirst().orElse("Unknown Food");
    }

    /**
     * Get saved recipes with cursor-based pagination
     */
    public CursorPageResponse<RecipeSummaryDto> getSavedRecipesWithCursor(Long userId, String cursor, int size) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<SavedRecipe> savedRecipes;
        if (cursorData == null) {
            savedRecipes = savedRecipeRepository.findSavedRecipesWithCursorInitial(userId, pageable);
        } else {
            savedRecipes = savedRecipeRepository.findSavedRecipesWithCursor(userId, cursorData.createdAt(), cursorData.id(), pageable);
        }

        List<RecipeSummaryDto> content = savedRecipes.getContent().stream()
                .map(sr -> convertToSummary(sr.getRecipe()))
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
    public UnifiedPageResponse<RecipeSummaryDto> getSavedRecipesUnified(Long userId, String cursor, Integer page, int size) {
        if (cursor != null && !cursor.isEmpty()) {
            return getSavedRecipesWithCursorUnified(userId, cursor, size);
        } else if (page != null) {
            return getSavedRecipesWithOffset(userId, page, size);
        } else {
            return getSavedRecipesWithCursorUnified(userId, null, size);
        }
    }

    /**
     * Offset-based saved recipes for web clients.
     */
    private UnifiedPageResponse<RecipeSummaryDto> getSavedRecipesWithOffset(Long userId, int page, int size) {
        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<SavedRecipe> savedRecipes = savedRecipeRepository.findSavedRecipesPage(userId, pageable);
        Page<RecipeSummaryDto> mappedPage = savedRecipes.map(sr -> convertToSummary(sr.getRecipe()));

        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based saved recipes wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<RecipeSummaryDto> getSavedRecipesWithCursorUnified(Long userId, String cursor, int size) {
        CursorPageResponse<RecipeSummaryDto> cursorResponse = getSavedRecipesWithCursor(userId, cursor, size);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }
}
