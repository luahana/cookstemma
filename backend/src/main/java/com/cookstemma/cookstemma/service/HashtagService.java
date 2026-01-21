package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import com.cookstemma.cookstemma.dto.hashtag.HashtagDto;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.repository.hashtag.HashtagRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.util.CursorUtil;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HashtagService {
    private final HashtagRepository hashtagRepository;
    private final RecipeRepository recipeRepository;
    private final LogPostRepository logPostRepository;
    private final UserRepository userRepository;
    private final RecipeLogRepository recipeLogRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * Get all hashtags
     */
    public List<HashtagDto> getAllHashtags() {
        return hashtagRepository.findAll().stream()
                .map(HashtagDto::from)
                .toList();
    }

    /**
     * Search hashtags by name prefix (for autocomplete)
     */
    public List<HashtagDto> searchHashtags(String query) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        String normalizedQuery = normalizeHashtagName(query);
        return hashtagRepository.findByNameContainingIgnoreCase(normalizedQuery).stream()
                .map(HashtagDto::from)
                .toList();
    }

    /**
     * Get or create hashtags from a list of names.
     * Returns a Set of Hashtag entities for association with recipes/log posts.
     */
    @Transactional
    public Set<Hashtag> getOrCreateHashtags(List<String> hashtagNames) {
        if (hashtagNames == null || hashtagNames.isEmpty()) {
            return new HashSet<>();
        }

        // Normalize hashtag names (remove # prefix if present, trim whitespace)
        List<String> normalizedNames = hashtagNames.stream()
                .map(this::normalizeHashtagName)
                .filter(name -> !name.isBlank())
                .distinct()
                .toList();

        if (normalizedNames.isEmpty()) {
            return new HashSet<>();
        }

        // Find existing hashtags
        List<Hashtag> existingHashtags = hashtagRepository.findByNameIn(normalizedNames);
        Set<String> existingNames = existingHashtags.stream()
                .map(Hashtag::getName)
                .collect(Collectors.toSet());

        // Create new hashtags for names that don't exist
        List<Hashtag> newHashtags = normalizedNames.stream()
                .filter(name -> !existingNames.contains(name))
                .map(name -> Hashtag.builder().name(name).build())
                .toList();

        if (!newHashtags.isEmpty()) {
            hashtagRepository.saveAll(newHashtags);
        }

        // Combine existing and new hashtags
        Set<Hashtag> allHashtags = new HashSet<>(existingHashtags);
        allHashtags.addAll(newHashtags);
        return allHashtags;
    }

    /**
     * Normalize hashtag name: remove # prefix, trim whitespace, convert to lowercase
     */
    private String normalizeHashtagName(String name) {
        if (name == null) {
            return "";
        }
        String trimmed = name.trim();
        if (trimmed.startsWith("#")) {
            trimmed = trimmed.substring(1);
        }
        return trimmed.toLowerCase();
    }

    // ==================== CONTENT BY HASHTAG ====================

    /**
     * Get recipes tagged with a specific hashtag (unified pagination)
     * Filters by translation availability based on locale
     */
    public UnifiedPageResponse<RecipeSummaryDto> getRecipesByHashtag(
            String hashtagName, String cursor, Integer page, int size, String locale) {

        String normalizedName = normalizeHashtagName(hashtagName);
        if (normalizedName.isBlank()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        // Check if hashtag exists
        if (hashtagRepository.findByName(normalizedName).isEmpty()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        // Extract language code for translation filtering
        String langCode = LocaleUtils.getLanguageCode(normalizedLocale);

        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<Recipe> recipes;
        if (cursorData == null) {
            recipes = recipeRepository.findByHashtagWithCursorInitial(normalizedName, langCode, pageable);
        } else {
            recipes = recipeRepository.findByHashtagWithCursor(
                    normalizedName, langCode, cursorData.createdAt(), cursorData.id(), pageable);
        }

        List<RecipeSummaryDto> content = recipes.getContent().stream()
                .map(recipe -> convertToRecipeSummary(recipe, normalizedLocale))
                .toList();

        String nextCursor = null;
        if (recipes.hasNext() && !recipes.getContent().isEmpty()) {
            Recipe lastItem = recipes.getContent().get(recipes.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getId());
        }

        return UnifiedPageResponse.fromCursor(content, nextCursor, size);
    }

    /**
     * Get log posts tagged with a specific hashtag (unified pagination)
     * Filters by translation availability based on locale
     */
    public UnifiedPageResponse<LogPostSummaryDto> getLogPostsByHashtag(
            String hashtagName, String cursor, Integer page, int size, String locale) {

        String normalizedName = normalizeHashtagName(hashtagName);
        if (normalizedName.isBlank()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        // Check if hashtag exists
        if (hashtagRepository.findByName(normalizedName).isEmpty()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        // Extract language code for translation filtering
        String langCode = LocaleUtils.getLanguageCode(normalizedLocale);

        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<LogPost> logPosts;
        if (cursorData == null) {
            logPosts = logPostRepository.findByHashtagWithCursorInitial(normalizedName, langCode, pageable);
        } else {
            logPosts = logPostRepository.findByHashtagWithCursor(
                    normalizedName, langCode, cursorData.createdAt(), cursorData.id(), pageable);
        }

        List<LogPostSummaryDto> content = logPosts.getContent().stream()
                .map(logPost -> convertToLogPostSummary(logPost, normalizedLocale))
                .toList();

        String nextCursor = null;
        if (logPosts.hasNext() && !logPosts.getContent().isEmpty()) {
            LogPost lastItem = logPosts.getContent().get(logPosts.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getId());
        }

        return UnifiedPageResponse.fromCursor(content, nextCursor, size);
    }

    /**
     * Get counts for a specific hashtag
     */
    public HashtagCountsDto getHashtagCounts(String hashtagName) {
        String normalizedName = normalizeHashtagName(hashtagName);
        if (normalizedName.isBlank() || hashtagRepository.findByName(normalizedName).isEmpty()) {
            return new HashtagCountsDto(false, normalizedName, 0, 0);
        }

        long recipeCount = recipeRepository.countByHashtag(normalizedName);
        long logPostCount = logPostRepository.countByHashtag(normalizedName);

        return new HashtagCountsDto(true, normalizedName, recipeCount, logPostCount);
    }

    /**
     * DTO for hashtag counts
     */
    public record HashtagCountsDto(
            boolean exists,
            String normalizedName,
            long recipeCount,
            long logPostCount
    ) {}

    // ==================== PRIVATE HELPER METHODS ====================

    private RecipeSummaryDto convertToRecipeSummary(Recipe recipe, String locale) {
        // 1. Creator info
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // 2. Food name from JSONB map (locale-aware)
        String foodName = LocaleUtils.getLocalizedValue(
                recipe.getFoodMaster().getName(),
                locale,
                recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));

        // 3. Thumbnail URL (first cover image from join table)
        String thumbnail = recipe.getCoverImages().stream()
                .filter(img -> img.getType() == ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // 4. Variant count
        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());

        // 5. Log count
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());

        // 6. Root recipe title (locale-aware)
        String rootTitle = null;
        if (recipe.getRootRecipe() != null) {
            rootTitle = LocaleUtils.getLocalizedValue(
                    recipe.getRootRecipe().getTitleTranslations(),
                    locale,
                    recipe.getRootRecipe().getTitle());
        }

        // 7. Hashtags (first 3)
        List<String> hashtags = recipe.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        // 8. Locale-aware title and description
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

    private LogPostSummaryDto convertToLogPostSummary(LogPost logPost, String locale) {
        // 1. Creator info
        User creator = userRepository.findById(logPost.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : null;

        // 2. Thumbnail URL (first image)
        String thumbnailUrl = logPost.getImages().stream()
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // 3. Rating, food name, and recipe title from recipe log (locale-aware)
        Integer rating = logPost.getRecipeLog() != null ? logPost.getRecipeLog().getRating() : null;
        String foodName = null;
        String recipeTitle = null;
        boolean isVariant = false;

        if (logPost.getRecipeLog() != null && logPost.getRecipeLog().getRecipe() != null) {
            Recipe linkedRecipe = logPost.getRecipeLog().getRecipe();
            foodName = LocaleUtils.getLocalizedValue(
                    linkedRecipe.getFoodMaster().getName(),
                    locale,
                    linkedRecipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));
            recipeTitle = LocaleUtils.getLocalizedValue(
                    linkedRecipe.getTitleTranslations(), locale, linkedRecipe.getTitle());
            isVariant = linkedRecipe.getParentRecipe() != null;
        }

        // 4. Hashtags (first 3)
        List<String> hashtags = logPost.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        // 5. Locale-aware title and content
        String localizedTitle = LocaleUtils.getLocalizedValue(
                logPost.getTitleTranslations(), locale, logPost.getTitle());
        String localizedContent = LocaleUtils.getLocalizedValue(
                logPost.getContentTranslations(), locale, logPost.getContent());

        return new LogPostSummaryDto(
                logPost.getPublicId(),
                localizedTitle,
                localizedContent,
                rating,
                thumbnailUrl,
                creatorPublicId,
                userName,
                foodName,
                recipeTitle,
                hashtags,
                isVariant,
                logPost.getIsPrivate() != null ? logPost.getIsPrivate() : false
        );
    }
}
